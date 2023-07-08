//
//  CopyButton.swift
//  Harbour
//
//  Created by royal on 08/08/2023.
//

import CommonHaptics
import SwiftUI

struct CopyButton: View {
	@Environment(\.showIndicator) private var showIndicatorAction
	let title: String
	let content: String?
	let showIndicator: Bool
	let action: (() -> String?)?

	init(_ title: String = Localizable.Generic.copy, content: String?, showIndicator: Bool = true) {
		self.title = title
		self.content = content
		self.showIndicator = showIndicator
		self.action = nil
	}

	init(_ title: String = Localizable.Generic.copy, showIndicator: Bool = true, action: @escaping () -> String?) {
		self.title = title
		self.content = nil
		self.showIndicator = showIndicator
		self.action = action
	}

	var body: some View {
		Button {
			Haptics.generateIfEnabled(.selectionChanged)
			if showIndicator {
				showIndicatorAction(.copied)
			}

			let content = self.content ?? self.action?()

			#if os(macOS)
			if let content {
				NSPasteboard.general.setString(content, forType: .string)
			}
			#else
			UIPasteboard.general.string = content
			#endif
		} label: {
			Label(title, systemImage: SFSymbol.copy)
		}
	}
}

#Preview {
	CopyButton(content: "Content")
}
