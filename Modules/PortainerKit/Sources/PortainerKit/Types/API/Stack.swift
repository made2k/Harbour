//
//  Stack.swift
//  PortainerKit
//
//  Created by royal on 06/06/2023.
//  Copyright © 2023 shameful. All rights reserved.
//

import Foundation

// MARK: - Stack

public struct Stack: Identifiable, Equatable, Decodable, Sendable {
	enum CodingKeys: String, CodingKey {
		case id = "Id"
		case name = "Name"
		case type = "Type"
		case endpointID = "EndpointId"
		case env = "Env"
		case status = "Status"
	}

	/// Stack Identifier
	public let id: Int

	/// Stack name
	public let name: String

	/// Stack type. 1 for a Swarm stack, 2 for a Compose stack
	public let type: StackType

	/// Environment(Endpoint) identifier. Reference the environment(endpoint) that will be used for deployment
	public let endpointID: Int

	/// A list of environment(endpoint) variables used during stack deployment
	public let env: [EnvironmentEntry]

	/// Stack status (1 - active, 2 - inactive)
	public var status: Status
}

// MARK: - Stack+StackType

public extension Stack {
	enum StackType: Int, Equatable, Decodable, Sendable {
		case swarm = 1
		case dockerCompose = 2
	}
}

// MARK: - Stack+Status

public extension Stack {
	enum Status: Int, Equatable, Decodable, Sendable {
		case active = 1
		case inactive = 2
	}
}

// MARK: - Stack+EnvironmentEntry

public extension Stack {
	struct EnvironmentEntry: Equatable, Decodable, Sendable {
		let name: String
		let value: String
	}
}
