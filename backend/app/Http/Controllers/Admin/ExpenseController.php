<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;

class ExpenseController extends Controller
{
    public const CATEGORIES = ['server', 'storage', 'store_fee', 'marketing', 'other'];

    public function index()
    {
        $expenses = Expense::latest('date')->latest('id')->paginate(25);

        return Inertia::render('Expenses/Index', [
            'expenses' => $expenses,
            'thisMonth' => (float) Expense::whereBetween('date', [now()->startOfMonth(), now()->endOfMonth()])->sum('amount'),
            'byCategory' => Expense::whereBetween('date', [now()->startOfMonth(), now()->endOfMonth()])
                ->selectRaw('category, SUM(amount) total')->groupBy('category')->pluck('total', 'category'),
        ]);
    }

    public function store(Request $request)
    {
        Expense::create($request->validate([
            'category' => ['required', Rule::in(self::CATEGORIES)],
            'description' => ['nullable', 'string', 'max:190'],
            'amount' => ['required', 'numeric', 'between:0.01,10000000'],
            'date' => ['required', 'date', 'before_or_equal:today'],
        ]) + ['currency' => 'TRY']);

        return back()->with('success', 'Gider eklendi.');
    }

    public function destroy(Expense $expense)
    {
        $expense->delete();

        return back()->with('success', 'Gider silindi.');
    }
}
