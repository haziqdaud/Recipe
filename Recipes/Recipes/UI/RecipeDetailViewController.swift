import UIKit
import SnapKit

final class RecipeDetailViewController: UIViewController {
    // Properties
    private var recipe: Recipe
    var onChanged: (() -> Void)?
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let ingredientsLabel = UILabel()
    private let stepsLabel = UILabel()
    
    // Initialization
    init(recipe: Recipe) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        setupUI()
        configureUI()
        setupNavigationBar()
    }
    
    // Setup Methods
    private func setupViewController() {
        title = "Recipe Details"
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0) //
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .trash,
                target: self,
                action: #selector(deleteTapped)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(editTapped)
            )
        ]
        
        // Customize navigation bar appearance
        navigationController?.navigationBar.tintColor = .systemOrange
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
    }
    
    private func setupUI() {
        setupScrollView()
        setupContentStackView()
        setupImageView()
        setupTitleSection()
        setupIngredientsSection()
        setupStepsSection()
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupContentStackView() {
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.alignment = .fill
        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalToSuperview().offset(-40)
        }
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowRadius = 4
        imageView.layer.shadowOpacity = 0.1
        imageView.snp.makeConstraints { make in
            make.height.equalTo(240)
        }
        contentStackView.addArrangedSubview(imageView)
    }
    
    private func setupTitleSection() {
        let titleContainer = UIView()
        titleContainer.backgroundColor = .white
        titleContainer.layer.cornerRadius = 12
        titleContainer.layer.masksToBounds = true
        
        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, typeLabel])
        titleStackView.axis = .vertical
        titleStackView.spacing = 8
        titleStackView.alignment = .leading
        
        titleContainer.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        
        typeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        typeLabel.textColor = .systemOrange
        
        contentStackView.addArrangedSubview(titleContainer)
    }
    
    private func setupIngredientsSection() {
        ingredientsLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(
            makeSection("Ingredients", content: ingredientsLabel, icon: "list.bullet")
        )
    }
    
    private func setupStepsSection() {
        stepsLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(
            makeSection("Preparation", content: stepsLabel, icon: "number")
        )
    }
    
    private func configureUI() {
        configureTitleSection()
        configureIngredients()
        configureSteps()
        configureImage()
    }
    
    // Configuration Methods
    private func configureTitleSection() {
        titleLabel.text = recipe.title
        typeLabel.text = RecipeStore.shared.typeName(for: recipe.typeId).uppercased()
    }
    
    private func configureIngredients() {
        let ingredientsText = recipe.ingredients.map { "• \($0)" }.joined(separator: "\n")
        let attributedString = NSMutableAttributedString(string: ingredientsText)
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = 6
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: ingredientsText.count)
        )
        
        ingredientsLabel.attributedText = attributedString
        ingredientsLabel.font = .systemFont(ofSize: 16)
        ingredientsLabel.textColor = .darkGray
    }
    
    private func configureSteps() {
        let stepsText = recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n\n")
        let attributedString = NSMutableAttributedString(string: stepsText)
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 8
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: stepsText.count)
        )
        
        // Format step numbers
        recipe.steps.enumerated().forEach { index, _ in
            let searchString = "\(index + 1). "
            if let range = stepsText.range(of: searchString) {
                let nsRange = NSRange(range, in: stepsText)
                attributedString.addAttribute(
                    .font,
                    value: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    range: nsRange
                )
                attributedString.addAttribute(.foregroundColor, value: UIColor.systemOrange, range: nsRange)
            }
        }
        
        attributedString.addAttribute(
            .foregroundColor,
            value: UIColor.darkGray,
            range: NSRange(location: 0, length: stepsText.count)
        )
        
        stepsLabel.attributedText = attributedString
        stepsLabel.font = .systemFont(ofSize: 16)
    }
    
    private func configureImage() {
        imageView.image = RecipeStore.shared.loadImage(named: recipe.imageFilename)
    }
    
    //Factory Method
    private func makeSection(_ title: String, content: UIView, icon: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true
        
        let headerStackView = UIStackView()
        let iconImageView = UIImageView()
        let sectionTitleLabel = UILabel()
        let separator = UIView()
        let contentStackView = UIStackView()
        
        // Configure header stack
        headerStackView.axis = .horizontal
        headerStackView.spacing = 12
        headerStackView.alignment = .center
        
        // Configure icon
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .systemOrange
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { make in
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        
        // Configure title
        sectionTitleLabel.text = title
        sectionTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        sectionTitleLabel.textColor = .label
        
        // Configure separator
        separator.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        
        // Configure content
        content.setContentCompressionResistancePriority(.required, for: .vertical)
        
        headerStackView.addArrangedSubview(iconImageView)
        headerStackView.addArrangedSubview(sectionTitleLabel)
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.addArrangedSubview(headerStackView)
        contentStackView.addArrangedSubview(separator)
        contentStackView.addArrangedSubview(content)
        
        container.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        return container
    }
    
    // Action Methods
    @objc private func editTapped() {
        let editViewController = AddEditRecipeViewController(mode: .edit(recipe))
        editViewController.onSaved = { [weak self] in
            guard let self = self else { return }
            if let updatedRecipe = RecipeStore.shared.recipe(with: recipe.id) {
                self.recipe = updatedRecipe
                self.configureUI()
                self.onChanged?()
            }
        }
        navigationController?.pushViewController(editViewController, animated: true)
    }
    
    @objc private func deleteTapped() {
        let alertController = UIAlertController(
            title: "Delete Recipe",
            message: "This action cannot be undone.",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            RecipeStore.shared.delete(id: self.recipe.id)
            self.onChanged?()
            self.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}
