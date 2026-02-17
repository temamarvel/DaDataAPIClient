//
//  Models.swift
//  DaDataAPIClient
//
//  Created by Артем Денисов on 18.02.2026.
//

import Foundation

public struct DaDataSuggestionsResponse<T: Decodable & Sendable>: Decodable {
    public let suggestions: [DaDataSuggestion<T>]
}

public struct DaDataSuggestion<T: Decodable & Sendable>: Decodable, Sendable {
    public let value: String
    public let unrestrictedValue: String
    public let data: T
    
    private enum CodingKeys: String, CodingKey {
        case value
        case unrestrictedValue = "unrestricted_value"
        case data
    }
}

// MARK: - Party model (subset useful for validation)

public struct DaDataParty: Decodable, Sendable {
    public let inn: String?
    public let kpp: String?
    public let ogrn: String?
    
    public let type: String?              // "LEGAL" / "INDIVIDUAL" (usually)
    public let name: Name?
    public let management: Management?
    public let address: Address?
    public let state: State?
    public let okved: String?
    public let okvedType: String?
    
    private enum CodingKeys: String, CodingKey {
        case inn, kpp, ogrn, type, name, management, address, state, okved
        case okvedType = "okved_type"
    }
    
    public struct Name: Decodable, Sendable {
        public let fullWithOpf: String?
        public let shortWithOpf: String?
        public let latin: String?
        public let full: String?
        public let short: String?
        
        private enum CodingKeys: String, CodingKey {
            case fullWithOpf = "full_with_opf"
            case shortWithOpf = "short_with_opf"
            case latin, full, short
        }
    }
    
    public struct Management: Decodable, Sendable {
        public let name: String?
        public let post: String?
    }
    
    public struct State: Decodable, Sendable {
        public let status: String?          // "ACTIVE", etc.
        public let registrationDate: Int64?
        public let liquidationDate: Int64?
        
        private enum CodingKeys: String, CodingKey {
            case status
            case registrationDate = "registration_date"
            case liquidationDate = "liquidation_date"
        }
    }
    
    public struct Address: Decodable, Sendable {
        public let value: String?
        public let unrestrictedValue: String?
        public let data: AddressData?
        
        private enum CodingKeys: String, CodingKey {
            case value
            case unrestrictedValue = "unrestricted_value"
            case data
        }
    }
    
    public struct AddressData: Decodable, Sendable {
        public let postalCode: String?
        public let country: String?
        public let regionWithType: String?
        public let cityWithType: String?
        public let streetWithType: String?
        public let house: String?
        public let block: String?
        public let flat: String?
        public let fiasId: String?
        public let kladrId: String?
        
        private enum CodingKeys: String, CodingKey {
            case postalCode = "postal_code"
            case country
            case regionWithType = "region_with_type"
            case cityWithType = "city_with_type"
            case streetWithType = "street_with_type"
            case house, block, flat
            case fiasId = "fias_id"
            case kladrId = "kladr_id"
        }
    }
}
