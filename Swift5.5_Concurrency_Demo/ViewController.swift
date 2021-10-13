//
//  ViewController.swift
//  Swift5.5_Concurrency_Demo
//
//  Created by 逸风 on 2021/10/13.
//

import UIKit

let origins: [String] = [
    "http://image.jerryfans.com/sample.jpg",
    "http://image.jerryfans.com/iterm2_bg_image.jpg",
    "http://image.jerryfans.com/new_post.jpg"
                         ]

class ViewController: UIViewController {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 50, y: 150, width: 150, height: 150)
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.imageView)
        Task {
            let image = await self.loadImage()
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
        Task {
            guard let images = await multiImageLoad() else { return }
            DispatchQueue.main.async {
                print("multiImageLoad")
                print(images)
                //do your things
            }
        }
        Task {
            guard let images = await multiWaitFinishLoad() else { return }
            DispatchQueue.main.async {
                print("multiWaitFinishLoad")
                print(images)
                //do your things
            }
        }
    }
    
    func oldwayLoad() {
        self.asyncLoadImage(url: "http://image.jerryfans.com/iterm2_bg_image.jpg") { [weak self] image in
            guard let self = self else { return }
            guard let img = image else { return }
            DispatchQueue.main.async {
                self.imageView.image = img
            }
        }
    }
    
    func downloadImage(url: String) async -> UIImage? {
        return await loadImage(url: url)
    }
    
    func loadImage(url: String = "http://image.jerryfans.com/iterm2_bg_image.jpg") async -> UIImage? {
        do {
            let rsp = try await URLSession.shared.download(from: URL(string: url)!, delegate: nil)
            return UIImage(contentsOfFile: rsp.0.path)
        } catch {
            return nil
        }
    }
    
    func asyncLoadImage(url: String, completion: ((_ image: UIImage?) -> ())?) {
        Task {
            let img = await loadImage(url: url)
            DispatchQueue.main.async {
                completion?(img)
            }
        }
    }
    func multiImageLoad() async -> [UIImage]? {
        var results: [UIImage] = []
        for ele in origins.enumerated() {
            results.append(await self.loadImage(url: origins[ele.offset])!)
        }
        return results
    }
    
    func multiImageLoad1() async -> [UIImage]? {
        var results: [UIImage] = []
        await withTaskGroup(of: UIImage.self) { taskGroup  in
            for ele in origins.enumerated() {
                taskGroup.addTask {
                    return await self.loadImage(url: origins[ele.offset])!
                }
            }
            for await result in taskGroup {
                results.append(result)
            }
        }
        return results
    }
    
    func multiWaitFinishLoad() async -> [UIImage]? {
        var results: [UIImage] = []
        await withTaskGroup(of: UIImage.self) { taskGroup  in
            for ele in origins.enumerated() {
                taskGroup.addTask {
                    print("begin ele \(ele.offset)")
                    return await self.loadImage(url: origins[ele.offset])!
                }
            }
            for await result in taskGroup {
                results.append(result)
            }
            //等待上面执行完，再做下面的事情
            await taskGroup.waitForAll()
            //取消全部
            // taskGroup.cancelAll()
            print("wait finished and do")
            results.append(await loadImage()!)
        }
        return results
    }
    
    func multiImageLoad_old() {
        let group = DispatchGroup()
        group.enter()
        // load img 1
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            group.leave()
        }
        
        group.enter()
        // load img 2
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            group.leave()
        }
        
        group.notify(queue: .main) {
            //do your things
        }
    }
    
}

