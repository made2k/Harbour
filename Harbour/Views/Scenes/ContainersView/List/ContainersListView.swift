//
//  ContainersListView.swift
//  Harbour
//
//  Created by royal on 23/07/2022.
//  Copyright © 2023 shameful. All rights reserved.
//

import PortainerKit
import SwiftUI

// MARK: - ContainersListView

struct ContainersListView: View {
	@Environment(\.portainerSelectedEndpointID) private var portainerSelectedEndpointID: Endpoint.ID?
	@EnvironmentObject private var sceneDelegate: SceneDelegate

	private let cellSpacing: Double = 8

	let containers: [Container]

	var body: some View {
		LazyVStack(spacing: cellSpacing) {
			ForEach(containers) { container in
				ContainersView.ContainerNavigationCell(container: container) {
					ContainerCell(container: container)
						.equatable()
				}
				.transition(.opacity)
				.contentShape(.contextMenuPreview, ContainerCell.roundedRectangleBackground)
				.contextMenu {
					ContainerContextMenu(container: container)
				}
			}
		}
	}
}

// MARK: - Previews

#Preview {
	ContainersListView(containers: [])
}
