//
//  ContainerLogsView.swift
//  Harbour
//
//  Created by royal on 21/01/2023.
//  Copyright © 2023 shameful. All rights reserved.
//

import CommonHaptics
import SwiftUI

// MARK: - ContainerLogsView

struct ContainerLogsView: View {
	@EnvironmentObject private var portainerStore: PortainerStore
	@Environment(\.errorHandler) private var errorHandler
	@Environment(\.showIndicator) private var showIndicator

	@State private var viewModel: ViewModel

	let navigationItem: ContainerNavigationItem

	init(navigationItem: ContainerNavigationItem) {
		self.navigationItem = navigationItem

		let viewModel = ViewModel(navigationItem: navigationItem)
		self._viewModel = .init(wrappedValue: viewModel)
	}

	var body: some View {
		ScrollViewReader { scrollProxy in
			ScrollView {
				if let logsViewable = viewModel.logsViewable {
					LogsView(logs: logsViewable)
				}
			}
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					ToolbarMenu(viewState: viewModel.viewState,
								lineCount: $viewModel.lineCount,
								includeTimestamps: $viewModel.includeTimestamps,
								shareableContent: viewModel.viewState.unwrappedValue,
								scrollAction: { scrollLogs(anchor: $0, scrollProxy: scrollProxy) },
								refreshAction: { viewModel.getLogs(errorHandler: errorHandler) })
				}
			}
		}
		.background(viewModel.viewState.backgroundView)
		.navigationTitle("ContainerLogsView.Title")
		.refreshable {
			await viewModel.getLogs(errorHandler: errorHandler).value
		}
//		.searchable(text: $searchQuery)
		.task(id: navigationItem.id) {
			await viewModel.getLogs(errorHandler: errorHandler).value
		}
		.onChange(of: viewModel.includeTimestamps) {
			viewModel.getLogs(errorHandler: errorHandler)
		}
	}
}

// MARK: - ContainerLogsView+Actions

private extension ContainerLogsView {
	func scrollLogs(anchor: UnitPoint, scrollProxy: ScrollViewProxy) {
		withAnimation {
			scrollProxy.scrollTo(LogsView.labelID, anchor: anchor)
		}
	}
}

// MARK: - ContainerLogsView+ToolbarMenu

private extension ContainerLogsView {
	struct ToolbarMenu: View {
		@Environment(\.showIndicator) private var showIndicator
		let viewState: ViewModel._ViewState
		@Binding var lineCount: Int
		@Binding var includeTimestamps: Bool
		let shareableContent: String?
		let scrollAction: (UnitPoint) -> Void
		let refreshAction: () -> Void

		@ViewBuilder
		private var refreshButton: some View {
			Button {
				Haptics.generateIfEnabled(.buttonPress)
				refreshAction()
			} label: {
				Label("Generic.Refresh", systemImage: SFSymbol.reload)
			}
		}

		@ViewBuilder
		private var scrollButtons: some View {
			Button {
				Haptics.generateIfEnabled(.light)
				scrollAction(.top)
			} label: {
				Label("ContainerLogsView.Menu.ScrollToTop", systemImage: SFSymbol.arrowUpLine)
			}

			Button {
				Haptics.generateIfEnabled(.light)
				scrollAction(.bottom)
			} label: {
				Label("ContainerLogsView.Menu.ScrollToBottom", systemImage: SFSymbol.arrowDownLine)
			}
		}

		@ViewBuilder
		private var includeTimestampsButton: some View {
			Button {
				Haptics.generateIfEnabled(.selectionChanged)
				includeTimestamps.toggle()
			} label: {
				Label("ContainerLogsView.Menu.IncludeTimestamps", systemImage: includeTimestamps ? SFSymbol.checkmark : "")
			}
		}

		@ViewBuilder
		private var logLinesMenu: some View {
			let lineCounts: [Int] = [
				100,
				1_000,
				10_000,
				100_000
			]
			Menu("ContainerLogsView.Menu.LineCount") {
				ForEach(lineCounts, id: \.self) { amount in
					let isSelected = lineCount == amount
					Button {
						Haptics.generateIfEnabled(.selectionChanged)
						lineCount = amount
					} label: {
						Label(amount.formatted(), systemImage: isSelected ? SFSymbol.checkmark : "")
					}
				}
			}
		}

		@ViewBuilder
		private var copyButton: some View {
			CopyButton(content: shareableContent)
		}

		@ViewBuilder
		private var shareButton: some View {
			if let shareableContent {
				ShareLink(item: shareableContent, preview: .init(.init(verbatim: shareableContent)))
			}
		}

		var body: some View {
			Menu {
				switch viewState {
				case .loading:
					Text("Generic.Loading")
				case .success:
					refreshButton
					Divider()
					scrollButtons
					Divider()
					includeTimestampsButton
					logLinesMenu
					Divider()
					copyButton
					shareButton
				default:
					refreshButton
				}
			} label: {
				Label("Generic.More", systemImage: SFSymbol.moreCircle)
			}
		}
	}
}

// MARK: - Previews

#Preview {
	ContainerLogsView(navigationItem: .init(id: "", displayName: "Containy", endpointID: nil))
}
