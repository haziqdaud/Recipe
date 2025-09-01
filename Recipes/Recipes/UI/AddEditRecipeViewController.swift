import UIKit
import SnapKit
import PhotosUI

final class AddEditRecipeViewController: UIViewController {
    enum Mode { case add(Recipe?), edit(Recipe) }
    private let mode: Mode
    var onSaved: (() -> Void)?
    
    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleField = UITextField()
    private let typeField = UITextField()
    private let picker = UIPickerView()
    private let imageView = UIImageView()
    private let chooseImageButton = UIButton(type: .system)
    private let ingredientsTextView = UITextView()
    private let stepsTextView = UITextView()
    private let imageContainer = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Data
    private var selectedTypeId: Int?
    private var currentImage: UIImage?
    private var originalImageFilename: String?
    
    // MARK: - Constants
    private enum Constants {
        static let cornerRadius: CGFloat = 16
        static let shadowOpacity: Float = 0.1
        static let shadowRadius: CGFloat = 4
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let contentInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        static let spacing: CGFloat = 24
        static let imageHeight: CGFloat = 200
        static let textViewHeight: CGFloat = 120
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLayout()
        fillIfEditing()
        setupNavigationBar()
        setupTextViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateShadows()
    }
    
    // MARK: - Setup Methods
    private func setupAppearance() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
        title = isEditingMode ? "Edit Recipe" : "New Recipe"
        
        // Customize navigation bar
        navigationController?.navigationBar.tintColor = .systemOrange
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem?.tintColor = .systemOrange
        navigationItem.leftBarButtonItem?.tintColor = .systemOrange
    }
    
    private func setupTextViews() {
        ingredientsTextView.delegate = self
        stepsTextView.delegate = self
        
        // Add placeholder functionality
        setupPlaceholder(for: ingredientsTextView, text: "Enter ingredients (one per line)")
        setupPlaceholder(for: stepsTextView, text: "Enter instructions (one per line)")
    }
    
    private func setupPlaceholder(for textView: UITextView, text: String) {
        if textView.text.isEmpty {
            textView.text = text
            textView.textColor = .placeholderText
        }
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentStack.axis = .vertical
        contentStack.spacing = Constants.spacing
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.contentInsets.top)
            make.leading.equalToSuperview().offset(Constants.contentInsets.left)
            make.trailing.equalToSuperview().offset(-Constants.contentInsets.right)
            make.bottom.equalToSuperview().offset(-Constants.contentInsets.bottom)
            make.width.equalToSuperview().offset(-Constants.contentInsets.left - Constants.contentInsets.right)
        }
        
        // Add sections
        contentStack.addArrangedSubview(createSection(title: "TITLE", view: titleField))
        contentStack.addArrangedSubview(createSection(title: "CATEGORY", view: typeField))
        contentStack.addArrangedSubview(createSection(title: "IMAGE", view: imageContainer))
        contentStack.addArrangedSubview(createSection(title: "INGREDIENTS (one per line)", view: ingredientsTextView))
        contentStack.addArrangedSubview(createSection(title: "INSTRUCTIONS (one per line)", view: stepsTextView))
        
        // Setup individual components
        setupTitleField()
        setupTypeField()
        setupImageSection()
        setupIngredientsTextView()
        setupStepsTextView()
    }
    
    private func setupTitleField() {
        titleField.placeholder = "Enter recipe title"
        titleField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleField.backgroundColor = .white
        titleField.layer.cornerRadius = Constants.cornerRadius
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        titleField.leftViewMode = .always
        titleField.delegate = self
        titleField.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    
    private func setupTypeField() {
        typeField.placeholder = "Select category"
        typeField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        typeField.backgroundColor = .white
        typeField.layer.cornerRadius = Constants.cornerRadius
        typeField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        typeField.leftViewMode = .always
        
        picker.dataSource = self
        picker.delegate = self
        typeField.inputView = picker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePicker))
        doneButton.tintColor = .systemOrange
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexibleSpace, doneButton]
        typeField.inputAccessoryView = toolbar
        typeField.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    
    private func setupImageSection() {
        imageContainer.backgroundColor = .white
        imageContainer.layer.cornerRadius = Constants.cornerRadius
        imageContainer.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        imageView.layer.cornerRadius = Constants.cornerRadius - 2
        
        chooseImageButton.setTitle("Choose Image", for: .normal)
        chooseImageButton.setTitleColor(.systemOrange, for: .normal)
        chooseImageButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        chooseImageButton.addTarget(self, action: #selector(chooseImage), for: .touchUpInside)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemOrange
        
        let stack = UIStackView(arrangedSubviews: [imageView, chooseImageButton, activityIndicator])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        imageContainer.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(Constants.imageHeight)
            make.width.equalTo(stack)
        }
    }
    
    private func setupIngredientsTextView() {
        setupTextView(ingredientsTextView)
        ingredientsTextView.isScrollEnabled = false
        ingredientsTextView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Constants.textViewHeight)
        }
    }
    
    private func setupStepsTextView() {
        setupTextView(stepsTextView)
        stepsTextView.isScrollEnabled = false
        stepsTextView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Constants.textViewHeight + 40)
        }
    }
    
    private func setupTextView(_ textView: UITextView) {
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.backgroundColor = .white
        textView.layer.cornerRadius = Constants.cornerRadius
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        textView.showsVerticalScrollIndicator = false
        textView.alwaysBounceVertical = false
    }
    
    private func createSection(title: String, view: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemOrange
        label.textAlignment = .left
        
        let stack = UIStackView(arrangedSubviews: [label, view])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }
    
    private func updateShadows() {
        let viewsToShadow: [UIView] = [titleField, typeField, imageContainer, ingredientsTextView, stepsTextView]
        
        viewsToShadow.forEach { view in
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = Constants.shadowOpacity
            view.layer.shadowRadius = Constants.shadowRadius
            view.layer.shadowOffset = Constants.shadowOffset
            view.layer.masksToBounds = false
        }
    }
    
    // MARK: - Data Handling
    private var isEditingMode: Bool {
        if case .edit = mode { return true } else { return false }
    }
    
    private func fillIfEditing() {
        switch mode {
        case .add(let suggestion):
            if let suggestion = suggestion {
                titleField.text = suggestion.title
                selectedTypeId = suggestion.typeId
                typeField.text = RecipeStore.shared.typeName(for: suggestion.typeId)
                if let row = RecipeStore.shared.recipeTypes.firstIndex(where: { $0.id == suggestion.typeId }) {
                    picker.selectRow(row, inComponent: 0, animated: false)
                }
            }
            
        case .edit(let recipe):
            titleField.text = recipe.title
            selectedTypeId = recipe.typeId
            typeField.text = RecipeStore.shared.typeName(for: recipe.typeId)
            ingredientsTextView.text = recipe.ingredients.joined(separator: "\n")
            stepsTextView.text = recipe.steps.joined(separator: "\n")
            originalImageFilename = recipe.imageFilename
            
            // Remove placeholder styling if there's content
            if !recipe.ingredients.isEmpty {
                ingredientsTextView.textColor = .darkGray
            }
            if !recipe.steps.isEmpty {
                stepsTextView.textColor = .darkGray
            }
            
            if let image = RecipeStore.shared.loadImage(named: recipe.imageFilename) {
                imageView.image = image
                currentImage = image
                chooseImageButton.setTitle("Change Image", for: .normal)
            }
            
            if let row = RecipeStore.shared.recipeTypes.firstIndex(where: { $0.id == recipe.typeId }) {
                picker.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func donePicker() {
        // Get the currently selected row from the picker
        let selectedRow = picker.selectedRow(inComponent: 0)
        
        // Update the text field with the selected category
        if selectedRow >= 0 && selectedRow < RecipeStore.shared.recipeTypes.count {
            let selectedType = RecipeStore.shared.recipeTypes[selectedRow]
            typeField.text = selectedType.name
            selectedTypeId = selectedType.id
        }
        
        view.endEditing(true) // Dismiss the keyboard
    }
    
    @objc private func chooseImage() {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.presentCameraPicker()
        })
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            self.presentPhotoPicker()
        })
        
        if imageView.image != nil {
            alert.addAction(UIAlertAction(title: "Remove Image", style: .destructive) { _ in
                self.currentImage = nil
                self.imageView.image = nil
                self.chooseImageButton.setTitle("Choose Image", for: .normal)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert("Camera not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func saveTapped() {
        guard validateForm() else { return }
        
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Process image asynchronously to avoid UI freeze
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var imageFilename: String?
            if let image = self.currentImage {
                do {
                    imageFilename = try RecipeStore.shared.saveImage(image)
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert("Failed to save image: \(error.localizedDescription)")
                        self.activityIndicator.stopAnimating()
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                    return
                }
            }
            
            // Create or update recipe on main thread
            DispatchQueue.main.async {
                self.saveRecipe(with: imageFilename)
            }
        }
    }
    
    private func validateForm() -> Bool {
        guard let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            showAlert("Please enter a title")
            return false
        }
        
        guard let typeId = selectedTypeId else {
            showAlert("Please choose a recipe type")
            return false
        }
        
        let ingredients = ingredientsTextView.text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if ingredients.isEmpty {
            showAlert("Please enter at least one ingredient")
            return false
        }
        
        let steps = stepsTextView.text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if steps.isEmpty {
            showAlert("Please enter at least one instruction step")
            return false
        }
        
        return true
    }
    
    private func saveRecipe(with imageFilename: String?) {
        let title = titleField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let typeId = selectedTypeId!
        
        let ingredients = ingredientsTextView.text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let steps = stepsTextView.text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        switch mode {
        case .add:
            let recipe = Recipe()
            recipe.title = title
            recipe.typeId = typeId
            recipe.imageFilename = imageFilename
            recipe.ingredients.append(objectsIn: ingredients)
            recipe.steps.append(objectsIn: steps)
            RecipeStore.shared.add(recipe)
            
        case .edit(let recipe):
            // Update the recipe properties
            recipe.title = title
            recipe.typeId = typeId
            
            // Clear and repopulate ingredients
            recipe.ingredients.removeAll()
            recipe.ingredients.append(objectsIn: ingredients)
            
            // Clear and repopulate steps
            recipe.steps.removeAll()
            recipe.steps.append(objectsIn: steps)
            
            // Only update image filename if we have a new image
            if let filename = imageFilename {
                recipe.imageFilename = filename
            }
            
            // Call RecipeStore's update method which handles the Realm transaction
            RecipeStore.shared.update(recipe)
        }
        
        activityIndicator.stopAnimating()
        navigationItem.rightBarButtonItem?.isEnabled = true
        onSaved?()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func cancelTapped() {
        if hasUnsavedChanges() {
            showUnsavedChangesAlert()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func hasUnsavedChanges() -> Bool {
        // Check if any field has been modified
        switch mode {
        case .add:
            return !titleField.text!.isEmpty ||
                   selectedTypeId != nil ||
                   currentImage != nil ||
                   !ingredientsTextView.text.isEmpty ||
                   !stepsTextView.text.isEmpty
        case .edit(let recipe):
            return titleField.text != recipe.title ||
                   selectedTypeId != recipe.typeId ||
                   currentImage != nil || // Image changed
                   ingredientsTextView.text != recipe.ingredients.joined(separator: "\n") ||
                   stepsTextView.text != recipe.steps.joined(separator: "\n")
        }
    }
    
    private func showUnsavedChangesAlert() {
        let alert = UIAlertController(
            title: "Unsaved Changes",
            message: "You have unsaved changes. Are you sure you want to discard them?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Alert
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Missing Information", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Extensions
extension AddEditRecipeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return RecipeStore.shared.recipeTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return RecipeStore.shared.recipeTypes[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, forComponent component: Int) {
        let type = RecipeStore.shared.recipeTypes[row]
        selectedTypeId = type.id
        typeField.text = type.name
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let type = RecipeStore.shared.recipeTypes[row]
        return NSAttributedString(
            string: type.name,
            attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
        )
    }
}

extension AddEditRecipeViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clear placeholder text
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .darkGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Restore placeholder if empty
        if textView.text.isEmpty {
            if textView == ingredientsTextView {
                textView.text = "Enter ingredients (one per line)"
            } else {
                textView.text = "Enter instructions (one per line)"
            }
            textView.textColor = .placeholderText
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Auto-resize text view
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
        
        textView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                if textView == ingredientsTextView {
                    constraint.constant = max(Constants.textViewHeight, newSize.height)
                } else if textView == stepsTextView {
                    constraint.constant = max(Constants.textViewHeight + 40, newSize.height)
                }
            }
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}

extension AddEditRecipeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            typeField.becomeFirstResponder()
        }
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AddEditRecipeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        if let image = image {
            currentImage = image
            imageView.image = image
            chooseImageButton.setTitle("Change Image", for: .normal)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension AddEditRecipeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                print("Error loading image: \(error)")
                return
            }
            
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.currentImage = image
                    self?.imageView.image = image
                    self?.chooseImageButton.setTitle("Change Image", for: .normal)
                }
            }
        }
    }
}
