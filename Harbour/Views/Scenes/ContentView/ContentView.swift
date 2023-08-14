//
//  ContentView.swift
//  Harbour
//
//  Created by royal on 17/07/2022.
//

import CommonFoundation
import CommonHaptics
import IndicatorsKit
import PortainerKit
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
	@EnvironmentObject private var appDelegate: AppDelegate
	@EnvironmentObject private var sceneDelegate: SceneDelegate
	@EnvironmentObject private var portainerStore: PortainerStore
	@EnvironmentObject private var preferences: Preferences
	@Environment(AppState.self) private var appState
	@Environment(\.errorHandler) private var errorHandler

	@State private var viewModel = ViewModel()

	@ViewBuilder
	private var titleMenu: some View {
		ForEach(portainerStore.endpoints) { endpoint in
			Button {
				Haptics.generateIfEnabled(.light)
				viewModel.selectEndpoint(endpoint)
			} label: {
				let isSelected = portainerStore.selectedEndpoint?.id == endpoint.id
				Label(endpoint.name ?? endpoint.id.description, systemImage: isSelected ? SFSymbol.checkmark : "")
			}
		}
	}

	@ToolbarContentBuilder
	private var toolbarMenu: some ToolbarContent {
		ToolbarItem(placement: .primaryAction) {
			Button {
//				Haptics.generateIfEnabled(.sheetPresentation)
				sceneDelegate.isSettingsSheetPresented.toggle()
			} label: {
				Label("ContentView.NavigationButton.Settings", systemImage: SFSymbol.settings)
			}
		}

		#if ENABLE_PREVIEW_FEATURES
		ToolbarItem(placement: .navigation) {
			NavigationLink {
				StacksView {
					viewModel.onStackTapped($0)
				}
			} label: {
				Label("ContentView.NavigationButton.Stacks", systemImage: SFSymbol.stack)
//					.symbolVariant(portainerStore.isSetup ? .none : .slash)
			}
		}
		#endif
	}

	@ViewBuilder
	private var containersView: some View {
		ScrollView {
//			#if ENABLE_PREVIEW_FEATURES
//			if isSummaryVisible {
//				VStack {
//					Text("ContentView.Summary")
//					Divider()
//				}
//				.transition(.move(edge: .top).combined(with: .opacity))
//			}
//			#endif

			ContainersView(viewModel.containers)
				.transition(.opacity)
				.animation(.easeInOut, value: viewModel.containers)
		}
		.background {
			if viewModel.shouldShowEmptyPlaceholderView {
				ContainersView.NoContainersPlaceholder(isEmpty: viewModel.containers.isEmpty, searchQuery: viewModel.searchText)
			}
		}
		.modifier(
			ContainersView.ListModifier {
				viewModel.viewState.backgroundView
			}
		)
		.searchable(
			text: $viewModel.searchText,
			tokens: $viewModel.searchTokens,
			suggestedTokens: .constant(viewModel.suggestedSearchTokens)
		) { token in
			Label(token.title, systemImage: token.icon)
		}
		.refreshable {
			do {
				try await viewModel.refresh()
			} catch {
				errorHandler(error)
			}
		}
	}

	// MARK: Body

	var body: some View {
		NavigationWrapped(useColumns: viewModel.shouldUseColumns) {
			containersView
				.navigationTitle(viewModel.navigationTitle)
				#if os(iOS)
				.navigationBarTitleDisplayMode(.inline)
				#endif
				.toolbarTitleMenu {
					titleMenu
				}
				.toolbar {
					toolbarMenu
				}
		} placeholderContent: {
			Text("ContentView.NoContainerSelectedPlaceholder")
				.foregroundStyle(.tertiary)
		}
		.sheet(isPresented: $sceneDelegate.isSettingsSheetPresented) {
			SettingsView()
				.indicatorOverlay(model: sceneDelegate.indicators)
		}
		.sheet(isPresented: $viewModel.isLandingSheetPresented) {
			viewModel.onLandingDismissed()
		} content: {
			LandingView()
				.indicatorOverlay(model: sceneDelegate.indicators)
		}
		.indicatorOverlay(model: sceneDelegate.indicators)
		.environment(\.errorHandler, .init(sceneDelegate.handleError))
		.environment(\.showIndicator, sceneDelegate.showIndicator)
		.environmentObject(sceneDelegate.indicators)
		.onOpenURL { url in
			sceneDelegate.onOpenURL(url)
		}
		.onContinueUserActivity(HarbourUserActivityIdentifier.containerDetails) { userActivity in
			sceneDelegate.onContinueContainerDetailsActivity(userActivity)
		}
//		.task {
//			do {
//				try await viewModel.refresh()
//			} catch {
//				errorHandler(error)
//			}
//		}
	}
}

// MARK: - Previews

#Preview {
	ContentView()
		.environment(AppState.shared)
		.environmentObject(PortainerStore.shared)
		.environmentObject(Preferences.shared)
}
