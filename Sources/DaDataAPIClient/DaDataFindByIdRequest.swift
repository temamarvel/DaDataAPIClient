//
//  DaDataFindByIdRequest.swift
//  DaDataAPIClient
//
//  Created by Артем Денисов on 18.02.2026.
//



internal struct DaDataFindByIdRequest: Encodable {
    let query: String
    let count: Int?
    init(query: String, count: Int?) {
        self.query = query
        self.count = count
    }
}
