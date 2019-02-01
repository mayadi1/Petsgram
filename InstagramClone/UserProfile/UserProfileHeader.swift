
import UIKit
import Firebase

//MARK: - UserProfileHeaderDelegate

protocol UserProfileHeaderDelegate {
    func didChangeToListView()
    func didChangeToGridView()
}

//MARK: - UserProfileHeader

class UserProfileHeader: UICollectionViewCell {
   
    var delegate: UserProfileHeaderDelegate?
    
    var user: User? {
        didSet {
            reloadData()
        }
    }
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
    private let postsLabel = UserProfileStatsLabel(value: 0, title: "posts")
    private let followersLabel = UserProfileStatsLabel(value: 0, title: "followers")
    private let followingLabel = UserProfileStatsLabel(value: 0, title: "following")
    
    private lazy var followButton: UserProfileFollowButton = {
        let button = UserProfileFollowButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(handleChangeToGridView), for: .touchUpInside)
        return button
    }()
    
    private lazy var listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "list"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        button.addTarget(self, action: #selector(handleChangeToListView), for: .touchUpInside)
        return button
    }()
    

    private let padding: CGFloat = 12
    
    static var headerId = "userProfileHeaderId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(profileImageView)
       profileImageView.anchor(top: topAnchor, left: centerXAnchor , paddingTop: 50, paddingLeft: -40, width: 80, height: 80)
        profileImageView.layer.cornerRadius = 80 / 2
        
        layoutUserStatsView()
        
        addSubview(followButton)
        followButton.anchor(top: postsLabel.superview?.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 2, height: 34)
        
        layoutBottomToolbar()
    }
    
    private func layoutUserStatsView() {
        let stackView = UIStackView(arrangedSubviews: [postsLabel, followersLabel, followingLabel])
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 50)
    }
    
    private func layoutBottomToolbar() {
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        
        let stackView = UIStackView(arrangedSubviews: [gridButton, listButton])
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        addSubview(bottomDividerView)
        
        stackView.anchor(top: followButton.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 44)
       
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
    }
    
    func reloadData() {
        guard let user = user else { return }
        reloadFollowButton()
        reloadUserStats()
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        }
    }
    
    private func reloadFollowButton() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let userId = user?.uid else { return }
        
        if currentLoggedInUserId == userId {
            followButton.type = .edit
            return
        }
        
        let previousButtonType = followButton.type
        followButton.type = .loading
        
        Database.database().isFollowingUser(withUID: userId, completion: { (following) in
            if following {
                self.followButton.type = .unfollow
            } else {
                self.followButton.type = .follow
            }
        }) { (err) in
            self.followButton.type = previousButtonType
        }
    }
    
    private func reloadUserStats() {
        guard let uid = user?.uid else { return }
        
        Database.database().numberOfPostsForUser(withUID: uid) { (count) in
            self.postsLabel.setValue(count)
        }
        
        Database.database().numberOfFollowersForUser(withUID: uid) { (count) in
            self.followersLabel.setValue(count)
        }
        
        Database.database().numberOfFollowingForUser(withUID: uid) { (count) in
            self.followingLabel.setValue(count)
        }
    }
    
    @objc private func handleTap() {
        guard let userId = user?.uid else { return }
        if followButton.type == .edit { return }
        
        let previousButtonType = followButton.type
        followButton.type = .loading
        
        if previousButtonType == .follow {
            Database.database().followUser(withUID: userId) { (err) in
                if err != nil {
                    self.followButton.type = previousButtonType
                    return
                }
                self.reloadFollowButton()
                self.reloadUserStats()
            }
            
        } else if previousButtonType == .unfollow {
            Database.database().unfollowUser(withUID: userId) { (err) in
                if err != nil {
                    self.followButton.type = previousButtonType
                    return
                }
                self.reloadFollowButton()
                self.reloadUserStats()
            }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
    }
    
    @objc private func handleChangeToGridView() {
        gridButton.tintColor = UIColor.mainBlue
        listButton.tintColor = UIColor(white: 0, alpha: 0.2)
        delegate?.didChangeToGridView()
    }
    
    @objc private func handleChangeToListView() {
        listButton.tintColor = UIColor.mainBlue
        gridButton.tintColor = UIColor(white: 0, alpha: 0.2)
        delegate?.didChangeToListView()
    }
}

//MARK: - UserProfileStatsLabel

private class UserProfileStatsLabel: UILabel {
    
    private var value: Int = 0
    private var title: String = ""
    
    init(value: Int, title: String) {
        super.init(frame: .zero)
        self.value = value
        self.title = title
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        numberOfLines = 0
        textAlignment = .center
        setAttributedText()
    }
    
    func setValue(_ value: Int) {
        self.value = value
        setAttributedText()
    }
    
    private func setAttributedText() {
        let attributedText = NSMutableAttributedString(string: "\(value)\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
        self.attributedText = attributedText
    }
}

//MARK: - FollowButtonType

private enum FollowButtonType {
    case loading, edit, follow, unfollow
}

//MARK: - UserProfileFollowButton

private class UserProfileFollowButton: UIButton {
    
    var type: FollowButtonType = .loading {
        didSet {
            configureButton()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 3
        configureButton()
    }
    
    private func configureButton() {
        switch type {
        case .loading:
            setupLoadingStyle()
        case .edit:
            setupEditStyle()
        case .follow:
            setupFollowStyle()
        case .unfollow:
            setupUnfollowStyle()
        }
    }
    
    private func setupLoadingStyle() {
        setTitle("Loading", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        isUserInteractionEnabled = false
    }
    
    private func setupEditStyle() {
        setTitle("Edit Profile", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        isUserInteractionEnabled = true
    }
    
    private func setupFollowStyle() {
        setTitle("Follow", for: .normal)
        setTitleColor(.white, for: .normal)
        backgroundColor = UIColor.mainBlue
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        isUserInteractionEnabled = true
    }
    
    private func setupUnfollowStyle() {
        setTitle("Unfollow", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        isUserInteractionEnabled = true
    }
}


