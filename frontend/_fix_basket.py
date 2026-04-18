with open('lib/batches_page.dart', 'r') as f:
    content = f.read()

replacements = [
    ('_api.getBatches()', '_api.getBaskets()'),
    ('_api.createBatch(', '_api.createBasket('),
    ('_api.updateBatch(', '_api.updateBasket('),
    ('_api.deleteBatch(', '_api.deleteBasket('),
    ('Unable to load batches:', 'Unable to load baskets:'),
    ('Batch saved to server.', 'Basket saved to server.'),
    ('Failed to save batch:', 'Failed to save basket:'),
    ("'Edit Batch'", "'Edit Basket'"),
    ('Batch updated on server.', 'Basket updated on server.'),
    ('Failed to update batch:', 'Failed to update basket:'),
    ('Select a batch to remove.', 'Select a basket to remove.'),
    ('Batch removed from server.', 'Basket removed from server.'),
    ('Failed to remove batch:', 'Failed to remove basket:'),
    ("title: 'Batches'", "title: 'Baskets'"),
    ("title: 'All Batches'", "title: 'All Baskets'"),
    ("title: 'Fresh Batches'", "title: 'Fresh Baskets'"),
    ("title: 'Spoiling Batches'", "title: 'Spoiling Baskets'"),
    ("title: 'Ripe Batches'", "title: 'Ripe Baskets'"),
    ("title: 'Spoiled Batches'", "title: 'Spoiled Baskets'"),
    ("title: 'Add New Batch'", "title: 'Add New Basket'"),
    ("title: 'Remove Batch'", "title: 'Remove Basket'"),
    ("Text('Remove Batch')", "Text('Remove Basket')"),
    ("Text('Add New Batch')", "Text('Add New Basket')"),
    ("Text('Save Batch')", "Text('Save Basket')"),
    ("Text('Confirm Remove Batch')", "Text('Confirm Remove Basket')"),
    ("totalLabel: 'Total Batches'", "totalLabel: 'Total Baskets'"),
    ("'Batch ID (e.g. Z-999)'", "'Basket ID (e.g. Z-999)'"),
    (" batches'", " baskets'"),
]

for old, new in replacements:
    content = content.replace(old, new)

with open('lib/batches_page.dart', 'w') as f:
    f.write(content)

print('Done')
