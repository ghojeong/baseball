//
//  NetworkService.swift
//  baseball
//
//  Created by 이다훈 on 2021/05/04.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire

protocol NetworkServiceable {
    func get<T: Codable>(path: APIPath, id: String?) -> Observable<T>
    func post<T: Codable>(path: APIPath, id: String?) -> Observable<T>
}

class NetworkService: NetworkServiceable {
    func get<T: Codable>(path: APIPath, id: String? = nil) -> Observable<T> {
        return Observable<T>.create({ observer in
            let endPoint = EndPoint.init(method: .get, path: path, id: id)
            
            var request : URLRequest {
                
                do {
                    let request = try endPoint.asURLRequest()
                    return request
                } catch {
                    assertionFailure("NetworkService.get.request")
                }
                return URLRequest.init(url: URL(string: "")!)
            }
            
            let dataRequest = AF.request(request)
            
            dataRequest.responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let model : T = try JSONDecoder().decode(T.self, from: data)
                        observer.onNext(model)
                    } catch  {
                        assertionFailure("NetworkService.get.dataRequest.responseData. case: .success")
                    }
                    
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create {
                dataRequest.cancel()
            }
        })
    }
    
    func post<T: Codable>(path: APIPath, id: String? = nil) -> Observable<T> {
        let path = "\"\(path)/\(id ?? "")"
        return RxAlamofire
            .request(.post, path, parameters: .none)
            .debug()
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .data()
            .map({ data -> T in
                return try JSONDecoder().decode(T.self, from: data)
            })
    }
}
