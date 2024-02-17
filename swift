import SwiftUI

enum ExpenseCategory: String, CaseIterable {
    case groceries
    case utilities
    case food
    case electricity
    case rent
    case fuel
    case houseHelp
    
    static var allCasesStrings: [String] {
        return allCases.map { $0.rawValue.capitalized }
    }
}

struct Expense: Identifiable {
    var id = UUID() // Add an identifier
    var date: Date
    var amount: Double
    var description: String
    var category: ExpenseCategory
}

class ExpenseManager: ObservableObject {
    @Published var expenses: [Expense] = []
    
    func addExpense(date: Date, amount: Double, description: String, category: ExpenseCategory) {
        let newExpense = Expense(date: date, amount: amount, description: description, category: category)
        expenses.append(newExpense)
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }
}

struct ContentView: View {
    var body: some View {
        ExpenseManagerView()
    }
}

struct ExpenseManagerView: View {
    @StateObject private var expenseManager = ExpenseManager()
    
    var body: some View {
        TabView {
            ExpensesTab(expenseManager: expenseManager)
                .tabItem {
                    Image(systemName: "dollarsign.circle")
                    Text("Expenses")
                }
            
            DailyLogTab(expenseManager: expenseManager)
                .tabItem {
                    Image(systemName: "calendar.circle")
                    Text("Daily Log")
                }
            
            SaverTab(expenseManager: expenseManager)
                .tabItem {
                    Image(systemName: "banknote")
                    Text("Saver")
                }
        }
    }
}

struct ExpensesTab: View {
    @ObservedObject var expenseManager: ExpenseManager
    @State private var showingAddExpense = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Expense")
                    .font(.title)
                    .padding()
                
                ExpenseFormView(expenseManager: expenseManager)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle("Expenses", displayMode: .inline)
        }
    }
}

struct DailyLogTab: View {
    @ObservedObject var expenseManager: ExpenseManager
    
    var body: some View {
        NavigationView {
            DailyLogView(expenseManager: expenseManager)
        }
    }
}

struct SaverTab: View {
    @ObservedObject var expenseManager: ExpenseManager
    @State private var monthlySavingGoal = ""
    @State private var savedAmount = ""
    @State private var remainingAmount: Double = 0
    
    var body: some View {
        VStack {
            Text("Saver Tab")
                .font(.title)
                .padding()

            Form {
                Section(header: Text("Savings Goal")) {
                    TextField("Monthly Saving Goal", text: $monthlySavingGoal)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Savings Progress")) {
                    TextField("Saved Amount", text: $savedAmount)
                        .keyboardType(.decimalPad)

                    Text("Remaining to Save: $\(String(format: "%.2f", remainingAmount))")
                        .foregroundColor(.blue)
                }
            }
            .onAppear {
                calculateRemainingAmount()
            }
            .onChange(of: savedAmount) { _ in
                calculateRemainingAmount()
            }

            Spacer()
        }
        .navigationBarTitle("Saver", displayMode: .inline)
    }

    private func calculateRemainingAmount() {
        guard let goal = Double(monthlySavingGoal),
              let saved = Double(savedAmount) else {
            return
        }

        remainingAmount = max(0, goal - saved)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ExpenseFormView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @State private var date = Date()
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategoryIndex = 0
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("Description", text: $description)
            }
            
            Section {
                Picker("Category", selection: $selectedCategoryIndex) {
                    ForEach(0..<ExpenseCategory.allCasesStrings.count, id: \.self) { index in
                        Text(ExpenseCategory.allCasesStrings[index])
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Button("Add Expense") {
                    if let amount = Double(amount) {
                        let selectedCategory = ExpenseCategory.allCases[selectedCategoryIndex]
                        expenseManager.addExpense(date: date, amount: amount, description: description, category: selectedCategory)
                        clearFields()
                    }
                }
            }
        }
    }
    
    private func clearFields() {
        date = Date()
        amount = ""
        description = ""
        selectedCategoryIndex = 0
    }
}

struct DailyLogView: View {
    @ObservedObject var expenseManager: ExpenseManager
    @State private var selectedCategoryIndex = 0

    var body: some View {
        VStack {
            Picker("Filter by Category", selection: $selectedCategoryIndex) {
                ForEach(0..<ExpenseCategory.allCasesStrings.count) { index in
                    Text(ExpenseCategory.allCasesStrings[index])
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            List {
                ForEach(filteredExpenses) { expense in
                    VStack(alignment: .leading) {
                        Text("Date: \(formattedDate(expense.date))")
                            .font(.headline)
                        Text("Amount: $\(String(format: "%.2f", expense.amount))")
                        Text("Description: \(expense.description)")
                        Text("Category: \(expense.category.rawValue.capitalized)")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.vertical, 5)
                }
            }

            Text("Total Spending: $\(String(format: "%.2f", totalSpending(for: selectedCategory)))")
                .font(.headline)
                .padding()
        }
    }

    private var selectedCategory: ExpenseCategory {
        return ExpenseCategory.allCases[selectedCategoryIndex]
    }

    private var filteredExpenses: [Expense] {
        return expenseManager.expenses.filter { $0.category == selectedCategory }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func totalSpending(for category: ExpenseCategory) -> Double {
        let categoryExpenses = expenseManager.expenses.filter { $0.category == category }
        return categoryExpenses.reduce(0) { $0 + $1.amount }
    }
}
