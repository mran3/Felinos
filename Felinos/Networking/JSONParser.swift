//
//  JSONParser.swift
//  Felinos
//
//  Created by Andrés A. on 5/15/20.
//  Copyright © 2020 Andrés A.. All rights reserved.
//

import UIKit

enum DataError: Error {
    case invalidResponse
    case invalidData
    case decodingError
    case serverError
}

class JSONParser {
    typealias result<T> = (Result<[T], Error>) -> Void
    let imageCache = NSCache<NSString, UIImage>()
    
    func downloadData<T: Decodable>(of type: T.Type, from url: URL, completion: @escaping result<T>) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(DataError.invalidResponse))
                return
            }
            
            if 200...299 ~= response.statusCode {
              if let data = data {
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedData: [T] = try jsonDecoder.decode([T].self, from: data)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(DataError.decodingError))
                }
              } else {
                completion(.failure(DataError.invalidData))
              }
             
            } else {
                completion(.failure(DataError.serverError))
            }
        }.resume()
    }
    
    func fetchImage(from urlString: String, completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        guard let url = URL(string: urlString) else {
              print("Error: Cannot create URL from string")
              return
        }
        return self.fetchImage(from: url, completion: completion)
    }
    
    func fetchImage(from url:URL, completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {          
   
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
                completion(cachedImage, nil)
            
        } else {
           let session = URLSession.shared
           let dataTask = session.dataTask(with: url) { (data, response, error) in
               if error != nil {
                   print("Error fetching the data from server!")
                   completion(nil, error)
               } else {
                if let data = data, let image = UIImage(data: data) {
                    self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
                    completion(image, nil)
                } else {
                    completion(nil, error)
                }
                
                   
               }
               
           }
           dataTask.resume()
       }
   }
    
}
