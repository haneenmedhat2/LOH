//
//  Requestable.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 21/12/2023.
//

import Foundation

protocol Requestable: RequestConvertible {
    
    associatedtype Response: Decodable
    
    var server: String {get}
    var method: RequestMethod {get}
    var path: String {get}
    var headerType: RequestHeaderType {get}
    var queries: APIParameters? {get}
    var body: APIParameters? {get}
    var uploads: [UploadData]? {get}
    var decoder: ResponseDecoder {get}
    var cachePolicy: URLRequest.CachePolicy {get}
    var timeoutInterval: TimeInterval {get}
    
}
extension Requestable {
    func asURLRequest() throws -> URLRequest {
        
        //MARK: - URL -
        guard let url = URL(string: server + path) else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        
        //MARK: - HTTTP Method -
        urlRequest.httpMethod = method.rawValue
        
        //MARK: - Common Headers -
        for header in headerType.header {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        //MARK: - Parameters -
        if let queries = queries?.compactMapValues({$0}) {
            urlRequest = try URLRequestEncoding.default.encode(urlRequest, with: queries)
        }
        if let body = body?.compactMapValues({$0}) {
            urlRequest = try JSONRequestEncoding.default.encode(urlRequest, with: body)
        }
        
        #if DEBUG
        APILogger.request(urlRequest, queries: queries?.compactMapValues { $0 } ?? [:],
                          body: body?.compactMapValues { $0 } ?? [:])
        #endif
        return urlRequest
    }
}
