"""Writes the synthetic .xls fixtures in test/fixtures/import/.

Dev-only (needs `pip install xlwt`); the app never runs Python. The real
Hysab Kytab export is personal and never committed, so these files stand
in for it: hk_sample.xls copies its exact layout (three sheets, every cell
stored as text), and biff8_cells.xls stresses the record types and string
table splitting. Expected values are worked out by hand in the tests.

    python3 tool/make_xls_fixtures.py
"""
import os
import xlwt

OUT = os.path.join(os.path.dirname(__file__), '..', 'test', 'fixtures', 'import')

HEADER = ['Voucher Type', 'Voucher Date', 'Voucher Amount', 'Description',
          'Category Name', 'Account Name', 'Tags', 'Events', 'Place',
          'Travel Currency Rate', 'Travel Currency Symbol',
          'Travel Currency Amount', 'Travel Location', 'Travel Date']


def row(kind, date, amount, account, note='', category='No Category',
        tags='', events='', place='', rate='', symbol='', foreign='0.0',
        location='', tdate=''):
    return [kind, date, amount, note, category, account, tags, events, place,
            rate, symbol, foreign, location, tdate]


ACTIVITIES = [
    row('Expense', '01/09/2026', '-2520.0', 'Meezan Bank', 'Lunch ',
        'Food & Drink', tags='Office, Lunch, office'),
    row('Income', '01/09/2026', '150000.0', 'Meezan Bank', category='Salary'),
    # Transfer: destination first, then source (as Hysab Kytab writes).
    row('Transfer', '02/09/2026', '5000.0', 'Cash'),
    row('Transfer', '02/09/2026', '-5000.0', 'Meezan Bank'),
    # Udhaar the Hysab Kytab way: the person is an account.
    row('Transfer', '03/09/2026', '10000.0', 'Mudassir Bhai', 'Loan'),
    row('Transfer', '03/09/2026', '-10000.0', 'Meezan Bank', 'Loan'),
    row('Transfer', '05/09/2026', '4000.0', 'Cash'),
    row('Transfer', '05/09/2026', '-4000.0', 'Mudassir Bhai'),
    # A foreign purchase with travel-currency fields.
    row('Expense', '06/09/2026', '-28250.0', 'Meezan Bank', 'Hotel',
        'Shopping', events='Dubai Trip', place='Mall of the Emirates',
        rate='282.5', symbol='$', foreign='100.0', location='Dubai',
        tdate='06/09/2026'),
    # A transfer with no partner.
    row('Transfer', '07/09/2026', '-1000.0', 'Nayapay'),
    row('Expense', '08/09/2026', '-150.0', 'Cash', 'چائے'),
    # Two genuinely identical expenses: both must import.
    row('Expense', '09/09/2026', '-100.0', 'Cash', 'Chai', 'Food & Drink'),
    row('Expense', '09/09/2026', '-100.0', 'Cash', 'Chai', 'Food & Drink'),
    row('Transfer', '10/09/2026', '3000.0', 'Cash'),
    row('Transfer', '10/09/2026', '-3000.0', 'Sami'),
    # Unreadable amount.
    row('Expense', '11/09/2026', 'abc', 'Cash', 'Broken'),
]

ACCOUNT = [
    ['Title', 'Opening Balance', 'Balance Amount', 'Closing Balance'],
    ['Cash', '500.0', '11650.0', '12150.0'],
    ['Meezan Bank', '10000.0', '104230.0', '114230.0'],
    ['Nayapay', '2000.0', '-1000.0', '1000.0'],
    ['Mudassir Bhai', '0.0', '6000.0', '6000.0'],
    ['Sami', '3000.0', '-3000.0', '0.0'],
]

CATEGORY = [
    ['Title', 'Balance Amount', 'Category Type'],
    ['Salary', '150000.0', 'Income'],
    ['Food & Drink', '-2720.0', 'Expense'],
    ['Shopping', '-28250.0', 'Expense'],
]


def sheet(book, name, rows):
    s = book.add_sheet(name)
    for r, values in enumerate(rows):
        for c, v in enumerate(values):
            s.write(r, c, v)


def hk_sample():
    book = xlwt.Workbook(encoding='utf-8')
    sheet(book, 'ACTIVITIES', [HEADER] + ACTIVITIES)
    sheet(book, 'ACCOUNT', ACCOUNT)
    sheet(book, 'CATEGORY', CATEGORY)
    book.save(os.path.join(OUT, 'hk_sample.xls'))


def biff8_cells():
    book = xlwt.Workbook(encoding='utf-8')
    s = book.add_sheet('Numbers')
    s.write(0, 0, 'int')
    s.write(0, 1, 'float')
    s.write(0, 2, 'neg')
    s.write(0, 3, 'big')
    for r in range(1, 6):
        s.write(r, 0, r * 10)          # RK / MULRK integers
        s.write(r, 1, r + 0.25)        # RK float or NUMBER
        s.write(r, 2, -r * 1.5)
        s.write(r, 3, 123456789.125)   # NUMBER
    s.write(7, 5, 'gap')               # sparse cell
    # 600 unique strings (~40 chars each, Latin and Urdu) push the shared
    # string table past one record, so strings split across CONTINUEs.
    t = book.add_sheet('Strings')
    for r in range(600):
        latin = 'row %04d %s' % (r, 'abcdefghij' * 3)
        urdu = 'قطار %04d %s' % (r, 'اردو متن ' * 3)
        t.write(r, 0, latin)
        t.write(r, 1, urdu)
    book.add_sheet('Empty')
    book.save(os.path.join(OUT, 'biff8_cells.xls'))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    hk_sample()
    biff8_cells()
