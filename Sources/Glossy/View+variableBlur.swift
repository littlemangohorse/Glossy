import SwiftUI

@available(iOS 17, macOS 14, macCatalyst 17, tvOS 17, visionOS 1, *)
public extension View {
	
	/// Applies a variable blur to the view, with the blur radius at each pixel determined by a mask image.
	///
	/// - Parameters:
	///   - radius: The radial size of the blur in areas where the mask is fully opaque.
	///   - maxSampleCount: The maximum number of samples the shader may take from the view's layer in each direction. Higher numbers produce a smoother, higher quality blur but are more GPU intensive. Values larger than `radius` have no effect. The default of 15 provides balanced results but may cause banding on some images at larger blur radii.
	///   - verticalPassFirst: Whether or not to perform the vertical blur pass before the horizontal one. Changing this parameter may reduce smearing artifacts. Defaults to `false`, i.e. perform the horizontal pass first.
	///   - mask: An `Image` to use as the mask for the blur strength.
	/// - Returns: The view with the variable blur effect applied.
	func variableBlur(
		radius: CGFloat,
		maxSampleCount: Int = 15,
		verticalPassFirst: Bool = false,
		mask: Image
	) -> some View {
		self.visualEffect { content, _ in
			content.variableBlur(
				radius: radius,
				maxSampleCount: maxSampleCount,
				verticalPassFirst: verticalPassFirst,
				mask: mask
			)
		}
	}
	
	/// Applies a variable blur to the view, with the blur radius at each pixel determined by a mask that you create.
	/// 
	/// - Parameters:
	///   - radius: The radial size of the blur in areas where the mask is fully opaque.
	///   - maxSampleCount: The maximum number of samples the shader may take from the view's layer in each direction. Higher numbers produce a smoother, higher quality blur but are more GPU intensive. Values larger than `radius` have no effect. The default of 15 provides balanced results but may cause banding on some images at larger blur radii.
	///   - verticalPassFirst: Whether or not to perform the vertical blur pass before the horizontal one. Changing this parameter may reduce smearing artifacts. Defaults to `false`, i.e. perform the horizontal pass first.
	///   - maskRenderer: A rendering closure to draw the mask used to determine the intensity of the blur at each pixel. The closure receives a `GeometryProxy` with the view's layout information, and a `GraphicsContext` to draw into.
	/// - Returns: The view with the variable blur effect applied.
	///
	/// The strength of the blur effect at any point on the view is determined by the transparency of the mask at that point. Areas where the mask is fully opaque are blurred by the full radius; areas where the mask is partially transparent are blurred by a proportionally smaller radius. Areas where the mask is fully transparent are left unblurred.
	///
	/// - Tip: To achieve a progressive blur or gradient blur, draw a gradient from transparent to opaque in your mask image where you want the transition from clear to blurred to take place.
	///
	/// - Note: Because the blur is split into horizontal and vertical passes for performance, certain mask images over certain patterns may cause "smearing" artifacts along one axis. Changing the `verticalPassFirst` parameter may reduce this, but may cause smearing in the other direction.. To avoid smearing entirely, avoid drawing hard edges in your `maskRenderer`.
	///
	/// - Important: Because this effect is implemented as a SwiftUI `layerEffect`, it is subject to the same limitations. Namely, views backed by AppKit or UIKit views may not render. Instead, they log a warning and display a placeholder image to highlight the error.
	func variableBlur(
		radius: CGFloat,
		maxSampleCount: Int = 15,
		verticalPassFirst: Bool = false,
		maskRenderer: @escaping (GeometryProxy, inout GraphicsContext) -> Void
	) -> some View {
		self.visualEffect { content, geometryProxy in
			content.variableBlur(
				radius: radius,
				maxSampleCount: maxSampleCount,
				verticalPassFirst: verticalPassFirst,
				mask: Image(size: geometryProxy.size, renderer: { context in
					maskRenderer(geometryProxy, &context)
				})
			)
		}
	}
}

#Preview("Image with progressive blur") {
	Image(systemName: "figure.walk.circle")
		.font(.system(size: 300))
		.variableBlur(radius: 30) { geometryProxy, context in
			// draw a linear gradient across the entire mask from top to bottom
			context.fill(
				Path(geometryProxy.frame(in: .local)),
				with: .linearGradient(
					.init(colors: [.white, .clear]),
					startPoint: .zero,
					endPoint: .init(x: 0, y: geometryProxy.size.height)
				)
			)
		}
}

#Preview("Vignette") {
	Image(systemName: "rectangle.checkered")
		.font(.system(size: 300))
		.variableBlur(radius: 100) { geometryProxy, context in
			// Add a blur to the mask to create the vignette effect
			context.addFilter(
				.blur(radius: 45)
			)
			
			// Mask off an ellipse centered on the view, where we don't want the variable blur applied
			context.clip(
				to: Path(
					ellipseIn: geometryProxy.frame(in: .local).insetBy(dx: 10, dy: 10)
				), options: .inverse
			)
			
			// Fill the entire context *except* the masked shape with an opaque color
			context.fill(
				Path(geometryProxy.frame(in: .local)),
				with: .color(.white)
			)
		}
}

#Preview("Blur masked using a shape") {
	Image(systemName: "circle.hexagongrid")
		.font(.system(size: 300))
		.variableBlur(radius: 30, verticalPassFirst: true) { geometryProxy, context in
			// draw a shape in an opaque color to apply the variable blur within the shape
			context.fill(
				Path(
					roundedRect: CGRect(
						origin: .init(
							x: geometryProxy.size.width / 5,
							y: geometryProxy.size.height / 4
						),
						size: .init(
							width: geometryProxy.size.width / 5 * 3,
							height: geometryProxy.size.height / 4 * 2
						)
					), cornerRadius: 40
				),
				with: .color(.white)
			)
		}
}

#Preview("Blur excluding a mask shape") {
	Image(systemName: "circle.hexagongrid")
		.font(.system(size: 300))
		.variableBlur(radius: 30) { geometryProxy, context in
			// Mask off a rounded rectangle where we don't want the blur applied
			context.clip(
				to: Path(
					roundedRect: CGRect(
						origin: .init(
							x: geometryProxy.size.width / 5,
							y: geometryProxy.size.height / 4
						),
						size: .init(
							width: geometryProxy.size.width / 5 * 3,
							height: geometryProxy.size.height / 4 * 2
						)
					), cornerRadius: 40
				), options: .inverse
			)
			
			// Fill the entire context *except* the masked shape with an opaque color
			context.fill(
				Path(geometryProxy.frame(in: .local)),
				with: .color(.white)
			)
		}
}

#Preview("Variable blur around a mask shape") {
	Image(systemName: "circle.hexagongrid")
		.font(.system(size: 300))
		.variableBlur(radius: 30) { geometryProxy, context in
			// blur what we draw to the mask so that the final effect fades around the masked shape
			context.addFilter(.blur(radius: 30))
			
			// draw a blurred rounded rectangle to the mask
			context.fill(
				Path(
					roundedRect: CGRect(
						origin: .init(
							x: geometryProxy.size.width / 5,
							y: geometryProxy.size.height / 4
						),
						size: .init(
							width: geometryProxy.size.width / 5 * 3,
							height: geometryProxy.size.height / 4 * 2
						)
					), cornerRadius: 40
				),
				with: .color(.white)
			)
		}
}

#Preview("Blurred background behind UI") {
	VStack(alignment: .center) {
		Spacer()
			.frame(maxWidth: .infinity)
		Text("This is a snowflake")
			.font(.headline)
			.fontWidth(.expanded)
		Text("With a variable blur powered by Metal.")
		HStack() {
			Button { } label: {
				Text("Let It Snow")
			}
			Button { } label: {
				Text("Don't Let It Snow")
			}
		}
		.padding(8)
		Text("Plot twist: nothing really happens when you press these buttons.")
			.textScale(.secondary)
			.opacity(0.6)
		#if !os(macOS)
		Spacer(minLength: 100)
		#endif
	}
	.buttonStyle(.bordered)
	.tint(.primary)
	.multilineTextAlignment(.center)
	.environment(\.backgroundMaterial, .thin) // this allows the buttons to take on their overlay appearance which looks good over the variable blur
	.scenePadding()
	.background {
		VStack {
			Image(systemName: "snowflake")
				.resizable()
				.scaledToFill()
				.fontWeight(.heavy)
				.padding(180)
				.foregroundStyle(.white)
		}
		.drawingGroup()
		.variableBlur(radius: 180) { geometryProxy, context in
			// add a blur to the mask to smooth out where the variable blur begins
			context.addFilter(.blur(radius: 40))
			
			context.fill(
				Path(CGRect(origin: .zero, size: geometryProxy.size)),
				with: .linearGradient(
					.init(colors: [.clear, .white]),
					startPoint: .init(x: 0, y: geometryProxy.size.height - 300),
					endPoint: .init(x: 0, y: geometryProxy.size.height)
				)
			)
		}
	}
	.background(.mint.gradient)
}
