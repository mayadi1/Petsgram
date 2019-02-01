
import UIKit
import Firebase

class HomeController: HomePostCellViewController {
   
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: HomePostCell.cellId)
        collectionView?.backgroundView = HomeEmptyStateView()
        collectionView?.backgroundView?.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateHomeFeed, object: nil)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        fetchAllPosts()
    }
    
    private func configureNavigationBar() {
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo").withRenderingMode(.alwaysOriginal))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
        //navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "inbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }
    
    private func fetchAllPosts() {
        showEmptyStateViewIfNeeded()
        collectionView?.refreshControl?.beginRefreshing()
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else {
            print("User ID not found :/")
            self.simpleAlert(title: "Error", message: "Try to sign out and sign in again, if this issue keeps happending contact support. ")
            return
        }
        
        fetchPostsForCurrentUser(currentUserId: currentLoggedInUserId){ (isCurrentUserPostsDone) in
            self.fetchFollowingUserPosts(currentUserId: currentLoggedInUserId){(isFollowingUsersPostsDone) in
                self.posts.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                })
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func fetchPostsForCurrentUser(currentUserId: String, completion: @escaping (Bool) -> ()){
        
        Database.database().fetchAllPosts(withUID: currentUserId, completion: { (posts) in
            self.posts.append(contentsOf: posts)
              completion(true)
        }) { (err) in
            print("oOOps err", err)
            completion(false)
        }
    }
    
    private func fetchFollowingUserPosts(currentUserId: String, completion: @escaping (Bool) -> ()){

        Database.database().reference().child("following").child(currentUserId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userIdsDictionary = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            userIdsDictionary.forEach({ (uid, value) in
                
                Database.database().fetchAllPosts(withUID: uid, completion: { (posts) in
                    self.posts.append(contentsOf: posts)
                    completion(true)
                }, withCancel: { (err) in
                    completion(false)
                })
            })
        }) { (err) in
              print("oOps err", err)
            completion(false)
        }
    }
    
    override func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfFollowingForUser(withUID: currentLoggedInUserId) { (followingCount) in
            Database.database().numberOfPostsForUser(withUID: currentLoggedInUserId, completion: { (postCount) in
                
                if followingCount == 0 && postCount == 0 {
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                        self.collectionView?.backgroundView?.alpha = 1
                    }, completion: nil)
                    
                } else {
                    self.collectionView?.backgroundView?.alpha = 0
                }
            })
        }
    }
    
    @objc private func handleRefresh() {
        posts.removeAll()
        fetchAllPosts()
    }
    
    @objc private func handleCamera() {
        let cameraController = CameraController()
        present(cameraController, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCell.cellId, for: indexPath) as! HomePostCell
        if indexPath.item < posts.count {
            cell.post = posts[indexPath.item]
        }
        cell.delegate = self
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension HomeController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dummyCell = HomePostCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1000))
        dummyCell.post = posts[indexPath.item]
        dummyCell.layoutIfNeeded()
        
        var height: CGFloat = dummyCell.header.bounds.height
        height += view.frame.width
        height += 24 + 2 * dummyCell.padding //bookmark button + padding
        height += dummyCell.captionLabel.intrinsicContentSize.height + 8
        return CGSize(width: view.frame.width, height: height)
    }
}
