//
//  IntentContainer.swift
//  Harbour
//
//  Created by royal on 10/06/2023.
//  Copyright © 2023 shameful. All rights reserved.
//

import AppIntents
import OSLog
import PortainerKit

private let logger = Logger(.intents(IntentContainer.self))

// MARK: - IntentContainer

struct IntentContainer: AppEntity, Identifiable, Hashable {
	static var typeDisplayRepresentation: TypeDisplayRepresentation = "IntentContainer.TypeDisplayRepresentation"
	static var defaultQuery = IntentContainerQuery()

	/// Container ID + display name
	var id: String {
		"\(_id):\(name ?? "")"
	}

	/// Actual container ID
	let _id: Container.ID

	/// Container display name
	let name: String?

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: .init(stringLiteral: name ?? ""), subtitle: .init(stringLiteral: _id))
	}

	init(id: Container.ID, name: String?) {
		self._id = id
		self.name = name
	}

	init(container: Container) {
		self._id = container.id
		self.name = container.displayName
	}
}

// MARK: - IntentContainer+Static

extension IntentContainer {
	static func preview(
		id: String = "PreviewContainerID",
		name: String = String(localized: "IntentContainer.Preview.Name")
	) -> Self {
		.init(id: id, name: name)
	}

	static func expandID(_ id: IntentContainer.ID) -> (Container.ID, String?) {
		// <containerID>:<containerName>
		let parts = id.split(separator: ":")
		if parts.count == 2 {
			return (String(parts[0]), String(parts[1]))
		}

		if let first = parts[safe: 0] {
			return (String(first), nil)
		}

		return (id, nil)
	}
}

// MARK: - IntentContainerQuery

struct IntentContainerQuery: EntityStringQuery {
	typealias Entity = IntentContainer

	@IntentParameterDependency<ContainerStatusIntent>(\.$endpoint, \.$resolveByName, \.$resolveOffline)
	var statusIntent

	private var endpoint: IntentEndpoint? {
		statusIntent?.endpoint
	}

	private var resolveByName: Bool {
		statusIntent?.resolveByName ?? false
	}

	private var resolveOffline: Bool {
		statusIntent?.resolveOffline ?? false
	}

	func entities(for identifiers: [Entity.ID]) async throws -> [Entity] {
		let parsed: [(Container.ID, String?)] = identifiers
			.compactMap { IntentContainer.expandID($0) }

		do {
			guard let endpoint else { return [] }

			let containers = try await getContainers(
				for: endpoint.id,
				ids: parsed.map(\.0),
				names: parsed.map(\.1),
				resolveByName: resolveByName
			)
			return containers.map { Entity(container: $0) }
		} catch {
			if resolveOffline && error is URLError {
				return parsed.map { .init(id: $0, name: $1) }
			}

			logger.error("\(error, privacy: .public) [\(String._debugInfo(), privacy: .public)]")
			throw error
		}
	}

	func entities(matching string: String) async throws -> [Entity] {
		do {
			guard let endpoint else { return [] }

			let containers = try await getContainers(for: endpoint.id, resolveByName: resolveByName)
			return containers
				.filter(string)
				.map { Entity(container: $0) }
		} catch {
			logger.error("\(error, privacy: .public) [\(String._debugInfo(), privacy: .public)]")
			return []
		}
	}

	func suggestedEntities() async throws -> [Entity] {
		guard let endpoint else { return [] }

		let containers = try await getContainers(for: endpoint.id, resolveByName: resolveByName)
		return containers.map { Entity(container: $0) }
	}
}

// MARK: - IntentContainerQuery+Static

extension IntentContainerQuery {
	func getContainers(
		for endpointID: Endpoint.ID,
		ids: [Container.ID]? = nil,
		names: [String?]? = nil,
		resolveByName: Bool
	) async throws -> [Container] {
		let portainerStore = IntentPortainerStore.shared
		try portainerStore.setupIfNeeded()

		let filters = Portainer.FetchFilters(
			id: resolveByName ? nil : ids,
			name: resolveByName ? names?.compactMap { $0 } : nil
		)
		let containers = try await portainerStore.getContainers(for: endpointID, filters: filters)
		return containers
	}
}
