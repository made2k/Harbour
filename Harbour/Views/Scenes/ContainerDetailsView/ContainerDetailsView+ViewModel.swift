//
//  ContainerDetailsView+ViewModel.swift
//  Harbour
//
//  Created by royal on 30/01/2023.
//  Copyright © 2023 shameful. All rights reserved.
//

import CommonFoundation
import CommonOSLog
import CoreSpotlight
import Foundation
import Observation
import OSLog
import PortainerKit

// MARK: - ContainerDetailsView+ViewModel

extension ContainerDetailsView {
	@Observable
	final class ViewModel: @unchecked Sendable {
		private nonisolated let portainerStore: PortainerStore = .shared
		private nonisolated let logger = Logger(.view(ContainerDetailsView.self))

		private(set) var viewState: ViewState<(Container?, ContainerDetails?), Error> = .loading
		private(set) var fetchTask: Task<Void, Never>?

		var navigationItem: ContainerNavigationItem

		var container: Container? {
			viewState.unwrappedValue?.0
		}

		var containerDetails: ContainerDetails? {
			viewState.unwrappedValue?.1
		}

		init(navigationItem: ContainerNavigationItem) {
			self.navigationItem = navigationItem
			self.viewState = .reloading((self.container(for: navigationItem), nil))
		}

		@MainActor
		func createUserActivity(_ userActivity: NSUserActivity, navigationItem: ContainerNavigationItem?) {
			let navigationItem = navigationItem ?? self.navigationItem
			let identifier = "\(HarbourUserActivityIdentifier.containerDetails).\(navigationItem.endpointID ?? -1).\(navigationItem.id)"

			let container = self.container(for: navigationItem)

			userActivity.isEligibleForHandoff = true
			#if os(iOS)
			userActivity.isEligibleForPrediction = false
			#endif
			userActivity.isEligibleForSearch = true

//			let displayName = navigationItem.displayName ?? navigationItem.id
//			userActivity.title = String(localized: "UserActivity.ContainerDetails.Title Name:\(displayName)")
			userActivity.title = navigationItem.displayName
//			userActivity.suggestedInvocationPhrase = Localization.title(displayName)

			let attributeSet = CSSearchableItemAttributeSet()
			attributeSet.contentType = HarbourItemType.container
//			attributeSet.title = String(localized: "UserActivity.ContainerDetails.Title Name:\(displayName)")
			attributeSet.title = navigationItem.displayName
//			attributeSet.contentDescription = String(localized: "UserActivity.ContainerDetails.Description Name:\(displayName)")
			if navigationItem.displayName != nil {
				attributeSet.contentDescription = navigationItem.id
			}
			userActivity.contentAttributeSet = attributeSet

			if let serverURL = portainerStore.serverURL,
			   let endpointID = navigationItem.endpointID {
				let portainerURLScheme = PortainerURLScheme(address: serverURL)
				let portainerURL = portainerURLScheme?.containerURL(containerID: navigationItem.id, endpointID: endpointID)
				userActivity.webpageURL = portainerURL
//				userActivity.referrerURL = portainerURL
			}

			if let containerNames = container?.names {
				userActivity.keywords = Set(containerNames)
			}

			userActivity.persistentIdentifier = identifier
			userActivity.targetContentIdentifier = identifier

			do {
				try userActivity.setTypedPayload(navigationItem)
				userActivity.requiredUserInfoKeys = [
					ContainerNavigationItem.CodingKeys.id.stringValue
				]
			} catch {
				logger.error("Failed to set payload: \(error, privacy: .public) [\(String._debugInfo(), privacy: .public)]")
			}

//			userActivity.becomeCurrent()
		}

		@MainActor @discardableResult
		func getContainerDetails(navigationItem: ContainerNavigationItem, errorHandler: ErrorHandler) -> Task<Void, Never> {
			fetchTask?.cancel()
			let task = Task {
				self.navigationItem = navigationItem
				self.viewState = viewState.reloadingUnwrapped

				do {
					if !portainerStore.isSetup {
						await portainerStore.setupTask?.value
					}

					async let _containers = portainerStore.fetchContainers(filters: .init(id: [navigationItem.id]))
					async let _containerDetails = portainerStore.inspectContainer(navigationItem.id, endpointID: navigationItem.endpointID)
					let (container, containerDetails) = try await (_containers.first, _containerDetails)

					guard !Task.isCancelled else { return }
					self.viewState = .success((container, containerDetails))
				} catch {
					guard !Task.isCancelled else { return }
					viewState = .failure(error)
					errorHandler(error)
				}
			}
			self.fetchTask = task
			return task
		}

		func container(for navigationItem: ContainerNavigationItem) -> Container? {
			if self.container?.id == navigationItem.id { return self.container }
			return portainerStore.containers.first { $0.id == navigationItem.id }
		}
	}
}
