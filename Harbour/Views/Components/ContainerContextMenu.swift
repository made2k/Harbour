//
//  ContainerContextMenu.swift
//  Harbour
//
//  Created by royal on 27/12/2022.
//  Copyright © 2023 shameful. All rights reserved.
//

import CommonHaptics
import IndicatorsKit
import PortainerKit
import SwiftUI

struct ContainerContextMenu: View {
	@EnvironmentObject private var sceneDelegate: SceneDelegate
	@EnvironmentObject private var portainerStore: PortainerStore
	@Environment(\.errorHandler) private var errorHandler
	@Environment(\.showIndicator) private var showIndicator
	@Environment(\.portainerServerURL) private var portainerServerURL: URL?
	@Environment(\.portainerSelectedEndpointID) private var portainerSelectedEndpointID: Endpoint.ID?

	private let killActionHaptic: Haptics.HapticStyle = .heavy

	let containerID: Container.ID
	let containerDisplayName: String?
	let containerState: ContainerState?
	let containerStatus: String?
	let containerIsStored: Bool

	init(container: Container) {
		self.containerID = container.id
		self.containerDisplayName = container.displayName
		self.containerState = container.state
		self.containerStatus = container.status
		self.containerIsStored = container._isStored
	}

	@ViewBuilder
	private var attachButton: some View {
		Button(action: attachAction) {
			Label("ContainerContextMenu.Attach", systemImage: SFSymbol.terminal)
		}
	}

	var body: some View {
		if !containerIsStored {
			Group {
				switch containerState {
				case .created:
					button(for: .pause)
					button(for: .stop)
					button(for: .restart)
					Divider()
					button(for: .kill, role: .destructive, haptic: killActionHaptic)
				case .running:
					button(for: .pause)
					button(for: .stop)
					button(for: .restart)
					Divider()
					button(for: .kill, role: .destructive, haptic: killActionHaptic)
				case .paused:
					button(for: .unpause)
					button(for: .stop)
					button(for: .restart)
					Divider()
					button(for: .kill, role: .destructive, haptic: killActionHaptic)
				case .restarting:
					button(for: .pause)
					button(for: .stop)
					Divider()
					button(for: .kill, role: .destructive, haptic: killActionHaptic)
				case .removing:
					button(for: .kill, role: .destructive, haptic: killActionHaptic)
				case .exited:
					button(for: .start)
				case .dead:
					button(for: .start)
				case .none:
					button(for: .unpause)
					button(for: .start)
					button(for: .restart)
					button(for: .pause)
					button(for: .stop)
					Divider()
					button(for: .kill, role: .destructive, haptic: killActionHaptic)
				}
			}

//			#if ENABLE_PREVIEW_FEATURES
//			Divider()
//
//			if containerState.isContainerOn {
//				attachButton
//			}
//			#endif
		}
	}

	private func button(for action: ExecuteAction, role: ButtonRole? = nil, haptic: Haptics.HapticStyle = .medium) -> some View {
		Button(role: role) {
			execute(action, haptic: haptic)
		} label: {
			Label(action.title, systemImage: action.icon)
		}
	}
}

// MARK: - ContainerContextMenu+Actions

private extension ContainerContextMenu {
	func execute(_ action: PortainerKit.ExecuteAction, haptic hapticStyle: Haptics.HapticStyle) {
		Haptics.generateIfEnabled(hapticStyle)

		showIndicator(.containerActionExecuted(containerID, containerDisplayName, action))

		Task {
			do {
				try await portainerStore.execute(action, on: containerID)
				portainerStore.refreshContainers(errorHandler: errorHandler)
			} catch {
				errorHandler(error, ._debugInfo())
			}
		}
	}

	func attachAction() {
		print(#function)

		Haptics.generateIfEnabled(.sheetPresentation)
//		do {
//			try Portainer.shared.attach(to: container)
//			sceneState.isContainerConsoleSheetPresented = true
//		} catch {
//			sceneState.handle(error)
//		}
	}
}
