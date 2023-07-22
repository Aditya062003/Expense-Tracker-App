import 'package:expense_tracker/widgets/chart/chart.dart';
import 'package:expense_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

class Expenses extends StatefulWidget {
  const Expenses(
      {super.key,
      required this.isDarkModeEnabled,
      required this.toggleDarkMode});

  final bool isDarkModeEnabled;
  final void Function() toggleDarkMode;
  @override
  State<Expenses> createState() {
    return _ExpensesState();
  }
}

class _ExpensesState extends State<Expenses> {
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPlaces(); // Load expenses from the database when the widget is created
  }

  final List<Expense> _registeredExpenses = [];
  Future<Database> _getDatabase() async {
    final dbpath = await sql.getDatabasesPath();
    final db = await sql.openDatabase(path.join(dbpath, 'expenses.db'),
        onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE expenses(id TEXT PRIMARY KEY, title TEXT, amount REAL, date DATETIME, category TEXT)');
    }, version: 1);
    return db;
  }

  Future<void> loadPlaces() async {
    setState(() {
      _isLoading = true;
    });
    final db = await _getDatabase();
    final expenses = await db.query('expenses');
    final loadedExpenses = expenses
        .map((e) => Expense(
              id: e['id'] as String,
              title: e['title'] as String,
              amount: e['amount'] as double,
              date:
                  DateTime.parse(e['date'] as String), // Handle nullable value
              category: Category.values
                  .firstWhere((element) => element.name == e['category']),
            ))
        .toList();
    setState(() {
      _isLoading = false;
    });
    setState(() => _registeredExpenses.addAll(loadedExpenses));
  }

  void toggleTheme() {
    setState(() {
      // widget.isDarkModeEnabled = !widget.isDarkModeEnabled;
      widget.toggleDarkMode();
    });
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(
        onAddExpense: _addExpense,
      ),
    );
  }

  void _addExpense(Expense expense) async {
    final db = await _getDatabase();
    await db.insert('expenses', {
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category.name,
    });

    setState(() {
      _registeredExpenses.add(expense); // Add the new expense to the list
    });
  }

  void _addRemovedExpense(Expense expense) async {
    final db = await _getDatabase();
    await db.insert('expenses', {
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category.name,
    });
  }

  void _removeExpense(Expense expense) async {
    final expenseIndex = _registeredExpenses.indexOf(expense);

    // 1. Remove the expense from the _registeredExpenses list using setState
    setState(() {
      _registeredExpenses.remove(expense);
    });

    // 2. Remove the expense from the database
    final db = await _getDatabase();
    await db.delete('expenses', where: 'id = ?', whereArgs: [expense.id]);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Expense Deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Re-insert the expense back into the list and add it to the database again
            setState(() {
              _registeredExpenses.insert(expenseIndex, expense);
            });
            _addRemovedExpense(expense);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    Widget mainContent = const Center(
      child: Text('No expense Found. Try adding some!'),
    );

    if (_registeredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _registeredExpenses,
        onRemoveItem: _removeExpense,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Expense Tracker'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkModeEnabled
                ? Icons.wb_sunny
                : Icons.nightlight_round),
            onPressed: toggleTheme,
          ),
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : width < 600
              ? Column(
                  children: [
                    Chart(expenses: _registeredExpenses),
                    Expanded(
                      child: mainContent,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Chart(expenses: _registeredExpenses),
                    ),
                    Expanded(
                      child: mainContent,
                    ),
                  ],
                ),
    );
  }
}
