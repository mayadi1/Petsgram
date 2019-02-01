//
//  stuff.swift
//  InstagramClone
//
//  Created by Mohamed Ayadi on 2/1/19.
//  Copyright © 2019 Mac Gallagher. All rights reserved.
//

import Foundation
guard let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as? ResultTableViewCell else {return UITableViewCell()}



override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
    
    if indexPath.row == results.count - 1{
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.startAnimating()
        spinner.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44)
        self.tableView.tableFooterView = spinner;
        guard let searchText = searchText,
            let pageNumber = pageNumber else {return}
        
        ResultController.shared.fetchResults(with: searchText, atPage: pageNumber+1) { (results) in
            if let results = results {
                DispatchQueue.main.async {
                    self.pageNumber = pageNumber+1
                    self.results.append(contentsOf: results.results)
                    tableView.reloadData()
                }
            } else {
                let label = UILabel()
                label.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44)
                label.text = "Sorry Nothing More"
                self.tableView.tableFooterView = label
            }
        }
    }
}


class ResultController {
    
    static let shared = ResultController()
    private init () {}
    
    func fetchResults(with searchText: String, atPage: Int, completion: @escaping (_ success: Results?)->Void){
        guard let baseURL = URL(string: "https://api.imgur.com/3/gallery/search/time") else {completion(nil);return}
        let pageNumber = String(atPage)
        var components = URLComponents(url: baseURL.appendingPathComponent(pageNumber), resolvingAgainstBaseURL: true)
        let queryItem = URLQueryItem(name: "q", value: searchText.lowercased())
        let typeQuery = URLQueryItem(name: "q_type", value: "jpg")
        components?.queryItems = [queryItem, typeQuery]
        guard let url = components?.url else {return}
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        let clientID = "126701cd8332f32"
        urlRequest.addValue("Client-ID \(clientID)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { (data, _, error) in
            guard let data = data else {completion(nil);return}
            do {
                let results = try JSONDecoder().decode(Results.self, from: data)
                completion(results)
                if let error = error { throw error }
            } catch {
                print("💩💩error fetching results \(error.localizedDescription), \(error)💩💩")
                completion(nil)
                return
            }
            }.resume()
    }
}




struct Results: Decodable {
    
    let results: [Result]
    
    private enum CodingKeys: String, CodingKey {
        case results = "data"
    }
    
}

struct Result: Decodable {
    
    let title: String
    var imageURLS: [URL]? {
        return images?.compactMap{$0.imageURL}
    }
    let images: [Images]?
}

struct Images: Decodable {
    let imageURL: URL
    private enum CodingKeys: String, CodingKey {
        case imageURL = "link"
    }
}


// Image Cache to prevent unessasary reloading of images

let imageCache = NSCache<NSString, AnyObject>()

// Custom Image View to assure images are being displayed in the currect cells

class CustomImageView: UIImageView {
    
    var urlString: String?
    
    func loadImage(with url: URL){
        
        urlString = url.absoluteString
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.startAnimating()
        spinner.frame = self.frame
        self.addSubview(spinner)
        image = nil
        //If image has already been loaded, pull from cache instead of loading twice
        if let image = imageCache.object(forKey: NSString(string: url.absoluteString)) as? UIImage {
            self.image = image
            spinner.removeFromSuperview()
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            DispatchQueue.main.async {
                guard let data = data,
                    let imageToCache = UIImage(data: data) else {return}
                if self.urlString == url.absoluteString {
                    self.image = imageToCache
                    spinner.removeFromSuperview()
                }
                imageCache.setObject(imageToCache, forKey: NSString(string: url.absoluteString))
                if let error = error {
                    print ("💩💩 error in file \(#file), function \(#function), \(error),\(error.localizedDescription)💩💩")
                }
            }
            }.resume()
    }
}

