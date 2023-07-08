//
//  SceneDelegate.swift
//  Harbour
//
//  Created by royal on 19/12/2022.
//

import CommonOSLog
import IndicatorsKit
import OSLog
import SwiftUI

final class SceneDelegate: NSObject, ObservableObject {
	let logger = Logger(category: String(describing: SceneDelegate.self))
	let indicators = Indicators()

	@Published var isSettingsSheetPresented = false
	@Published var navigationPath = NavigationPath()

	// MARK: Data State

	var isLoading: Bool {
		let portainerStore = PortainerStore.shared
		let setupTask = portainerStore.setupTask != nil
		let endpointsTask = portainerStore.endpointsTask != nil
		let containersTask = portainerStore.containersTask != nil
		return setupTask || endpointsTask || containersTask
	}
}
