import UIKit
import RealmSwift
import SnapKit

final class RecipeListViewController: UIViewController {
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var filteredRecipes: Results<Recipe>?
    private var selectedTypeId: Int?
    private var categories: Results<RecipeType>?
    
    // UI Components for the new design
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let backgroundImageView = UIImageView()
    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        setupBackground()
        setupHeader()
        setupCategoryCollectionView()
        configureTableView()
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Setup Methods
    private func setupViewController() {
        view.backgroundColor = .white
        categories = RecipeStore.shared.recipeTypes
    }
    
    private func setupBackground() {
        backgroundImageView.image = UIImage(named: "recipe-background") ?? createDefaultBackground()
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.7
        view.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func createDefaultBackground() -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        gradientLayer.colors = [
            UIColor(red: 0.95, green: 0.87, blue: 0.73, alpha: 1.00).cgColor,
            UIColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1.00).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        UIGraphicsBeginImageContext(gradientLayer.frame.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    private func setupHeader() {
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        titleLabel.text = "All recipes"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .darkText
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = .black // Changed to black
        addButton.addTarget(self, action: #selector(navigateToAddRecipe), for: .touchUpInside)
        headerView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
    }
    
    private func setupCategoryCollectionView() {
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: "CategoryCell")
        
        view.addSubview(categoryCollectionView)
        categoryCollectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
    }
    
    private func configureTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(categoryCollectionView.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        tableView.register(RecipeTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // MARK: - Data Methods
    private func reloadData() {
        filteredRecipes = RecipeStore.shared.getRecipesByType(selectedTypeId)
        tableView.reloadData()
    }
    
    // MARK: - Navigation Methods
    @objc private func navigateToAddRecipe() {
        let addViewController = AddEditRecipeViewController(mode: .add(nil))
        addViewController.onSaved = { [weak self] in
            self?.reloadData()
        }
        navigationController?.pushViewController(addViewController, animated: true)
    }
    
    private func navigateToRecipeDetail(_ recipe: Recipe) {
        let detailViewController = RecipeDetailViewController(recipe: recipe)
        detailViewController.onChanged = { [weak self] in
            self?.reloadData()
        }
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - Category Collection View
extension RecipeListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (categories?.count ?? 0) + 1 // +1 for the "All" button
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as? CategoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.item == 0 {
            // First cell is the "All" button
            let isSelected = selectedTypeId == nil
            cell.configure(with: "All", isSelected: isSelected)
        } else {
            // Other cells are categories
            if let category = categories?[indexPath.item - 1] {
                let isSelected = selectedTypeId == category.id
                cell.configure(with: category.name, isSelected: isSelected)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var text: String
        
        if indexPath.item == 0 {
            text = "All"
        } else {
            text = categories?[indexPath.item - 1].name ?? "Category"
        }
        
        let width = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]).width + 32
        return CGSize(width: width, height: 36)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            // "All" button selected - show all recipes
            selectedTypeId = nil
        } else {
            // Category selected
            selectedTypeId = categories?[indexPath.item - 1].id
        }
        collectionView.reloadData()
        reloadData()
    }
}

// MARK: - Category Collection View Cell
final class CategoryCollectionViewCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.black.cgColor // Changed to black
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            contentView.backgroundColor = .black // Changed to black
            titleLabel.textColor = .white
        } else {
            contentView.backgroundColor = .white
            titleLabel.textColor = .black // Changed to black
        }
    }
}

// MARK: - Recipe Table View Cell
final class RecipeTableViewCell: UITableViewCell {
    // UI Components
    private let containerView = UIView()
    private let recipeImageView = UIImageView()
    private let titleLabel = UILabel()
    private let categoryLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        // Container
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.1
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        // Recipe Image
        recipeImageView.contentMode = .scaleAspectFill
        recipeImageView.layer.cornerRadius = 12
        recipeImageView.clipsToBounds = true
        recipeImageView.backgroundColor = .secondarySystemBackground
        containerView.addSubview(recipeImageView)
        recipeImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.width.equalTo(100)
            make.height.equalTo(100)
        }
        
        // Title Label
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .darkText
        titleLabel.numberOfLines = 2
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(recipeImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // Category Label
        categoryLabel.font = .systemFont(ofSize: 14, weight: .medium)
        categoryLabel.textColor = .black // Changed to black
        containerView.addSubview(categoryLabel)
        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(recipeImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    
    func configure(with recipe: Recipe, categoryName: String?) {
        titleLabel.text = recipe.title
        categoryLabel.text = categoryName ?? "Uncategorized"
        
        // Load image
        if let imageFilename = recipe.imageFilename,
           let loadedImage = RecipeStore.shared.loadImage(named: imageFilename) {
            recipeImageView.image = loadedImage
        } else {
            recipeImageView.image = UIImage(named: "recipe-placeholder") ?? UIImage(systemName: "photo")
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension RecipeListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRecipes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? RecipeTableViewCell else {
            return UITableViewCell()
        }
        
        if let recipe = filteredRecipes?[indexPath.row] {
            // Get category name from your categories list
            let categoryName = categories?.first(where: { $0.id == recipe.typeId })?.name
            cell.configure(with: recipe, categoryName: categoryName)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let recipe = filteredRecipes?[indexPath.row] {
            navigateToRecipeDetail(recipe)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let recipe = filteredRecipes?[indexPath.row] else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.handleDelete(recipe: recipe, completion: completion)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .black // Changed to black
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func handleDelete(recipe: Recipe, completion: @escaping (Bool) -> Void) {
        RecipeStore.shared.delete(id: recipe.id)
        reloadData()
        completion(true)
    }
}
