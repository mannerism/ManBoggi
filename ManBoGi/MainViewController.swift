//
//  MainViewController.swift
//  ManBoGi
//
//  Created by Yu Juno on 2020/11/18.
//

import UIKit
import HealthKit

class MainViewController: UIViewController {
	var healthStore = HKHealthStore()
	let testLabel = UILabel()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .red
		getHealthInfo()
		testLabel.backgroundColor = .orange
		view.addSubview(testLabel)
		testLabel.translatesAutoresizingMaskIntoConstraints = false
		testLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		testLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		testLabel.widthAnchor.constraint(equalToConstant: 300).isActive = true
		testLabel.heightAnchor.constraint(equalToConstant: 100).isActive = true
	}
	
	private func getHealthInfo() {
		//Access Step Count
		let healthKitTypes: Set = [ HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]
		//Check for Authorization
		healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (isSuccess, error) in
			if isSuccess {
				//Auth Success
				self.getSteps { (result) in
					DispatchQueue.main.async {
						let stepCount = String(Int(result))
						self.testLabel.text = "걸음 수: \(stepCount)"
					}
				}
			}
		}
	}
	
	func getSteps(completion: @escaping (Double) -> ()) {
		let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
		let now = Date()
		let startOfDay = Calendar.current.date(byAdding: .day, value: -5, to: now)!
		var interval = DateComponents()
		interval.day = 7
		let query = HKStatisticsCollectionQuery(quantityType: type,
																					 quantitySamplePredicate: nil,
																					 options: [.cumulativeSum],
																					 anchorDate: startOfDay,
																					 intervalComponents: interval)
		query.initialResultsHandler = { _, result, error in
						var resultCount = 0.0
						result!.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
						if let sum = statistics.sumQuantity() {
								// Get steps (they are of double type)
								resultCount = sum.doubleValue(for: HKUnit.count())
						} // end if
							
						// Return
						DispatchQueue.main.async {
								completion(resultCount)
						}
				}
		}
		
		query.statisticsUpdateHandler = {
				query, statistics, statisticsCollection, error in

				// If new statistics are available
				if let sum = statistics?.sumQuantity() {
						let resultCount = sum.doubleValue(for: HKUnit.count())
						// Return
						DispatchQueue.main.async {
								completion(resultCount)
						}
				} // end if
		}
		healthStore.execute(query)
	}
}
