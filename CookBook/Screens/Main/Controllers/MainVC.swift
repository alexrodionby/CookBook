//
//  MainVC.swift
//  CookBook
//
//  Created by Alexandr Rodionov on 26.02.23.
//

import UIKit

class MainVC: UIViewController {
    
    private let preloadManagerDelegate = PreloadData()
    private let searchView = SearchView()
    private let recipeView = RecipeView()
    private let resipesByTypeDelegate: RestAPIProviderProtocol = RecipesManager()
    var selectedCategory = "all"
    var typesRicepsArray: [Result] = []
    var currentRicepsArray: [Recipe] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        recipeView.collectionView.dataSource = self
        recipeView.collectionView.delegate = self
        recipeView.recipesTableView.dataSource = self
        recipeView.recipesTableView.delegate = self
        setupView()
        getRecipesByTypeFirstTime(forKey: selectedCategory)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.recipeView.recipesTableView.reloadData()
        }
        print("!!!!!!! Показываем мэйн таблицу в который раз !!!!!!!!!")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        preloadManagerDelegate.configure()
        searchView.tableView.reloadData()
    }
    
    private func setupView() {
        view.addSubview(recipeView)
        NSLayoutConstraint.activate([
            recipeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            recipeView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            recipeView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            recipeView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func setupUICell(cell: UICollectionViewCell, color: UIColor) {
        cell.backgroundColor = color
        cell.layer.borderWidth = 0.0
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 3)
        cell.layer.shadowRadius = 3.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.cornerRadius = 15
    }
    
    private func getRecipesByTypeFirstTime(forKey key: String) {
        resipesByTypeDelegate.getRecipesByType(forType: key) { [weak self] recipe in
            if let recivedData = recipe.results {
                self?.typesRicepsArray.append(contentsOf: recivedData)
                DispatchQueue.main.async {
                    self?.recipeView.recipesTableView.reloadData()
                }
            }
        }
    }
}


extension MainVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        typesRicepsArray.removeAll()
        recipeView.isSelected = false
        if recipeView.lastIndexActive != indexPath {
            
            let cell = collectionView.cellForItem(at: indexPath) as! CategoryCell
            setupUICell(cell: cell, color: .lightGray)
            selectedCategory = recipeView.categories[indexPath.row]
            resipesByTypeDelegate.getRecipesByType(forType: selectedCategory) { [weak self] recipesData in
                guard let self = self else { return }
                if let recivedData = recipesData.results {
                    self.typesRicepsArray.append(contentsOf: recivedData)
                    DispatchQueue.main.async {
                        self.recipeView.recipesTableView.reloadData()
                    }
                }
            }
            print(selectedCategory)
            
            if let cell1 = collectionView.cellForItem(at: recipeView.lastIndexActive) as? CategoryCell {
                setupUICell(cell: cell1, color: .white)
            }
            recipeView.lastIndexActive = indexPath
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if recipeView.isSelected && indexPath == [0,0]{
            setupUICell(cell: cell, color: .lightGray)
            recipeView.isSelected = false
            recipeView.lastIndexActive = [0,0]
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recipeView.categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
        setupUICell(cell: cell, color: .white)
        let category = recipeView.categories[indexPath.row]
        cell.configure(with: category)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = recipeView.categories[indexPath.row]
        let cellWidth = text.size(withAttributes:[.font: UIFont.systemFont(ofSize: 14.0)]).width + 20.0
        return CGSize(width: cellWidth, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20) //отступы от секции
    }
}

extension MainVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionHeader") as! CustomHeader
        view.title.text = "Recipes"
        return view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typesRicepsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeCell.identifier, for: indexPath) as! RecipeCell
        let recipe = typesRicepsArray[indexPath.row]
        if PreloadData.favoriteRecips.contains(recipe) {
            //cell.liked = true
            cell.favouriteButton.setBackgroundImage(UIImage(named: "SaveActive"), for: .normal)
        } else {
            //cell.liked = false
            cell.favouriteButton.setBackgroundImage(UIImage(named: "SaveInactive"), for: .normal)
        }
        cell.configure(recipe)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = DetailedRecipeViewController()
        let selectedID = typesRicepsArray[indexPath.row].id
        resipesByTypeDelegate.getCurrentRecipesByID(forID: selectedID) { [weak self] recipesData in
            guard let self = self else { return }
            let recivedData = recipesData
            self.currentRicepsArray.append(recivedData)
            DispatchQueue.main.async {
                vc.contentView.configure(self.currentRicepsArray)
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
        self.currentRicepsArray.removeAll()
    }
}

