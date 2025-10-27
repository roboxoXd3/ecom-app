# Size Chart Management System - Implementation Guide

## 📋 Current System Analysis

### Database Current State
Based on analysis of your Supabase database:

**Products Table:**
- **Total Products**: 40
- **Products with Size Chart Templates**: 2 (5%)
- **Products with Custom Size Chart Data**: 0 (0%)
- **Size Chart Fields**:
  - `size_chart_template_id` (UUID, nullable)
  - `custom_size_chart_data` (JSONB, nullable)
  - `size_guide_type` (TEXT, default: 'template')

**Categories Distribution:**
- Electronics: 13 products (32.5%)
- Home & Garden: 7 products (17.5%)
- Fashion: 5 products (12.5%)
- Accessories: 5 products (12.5%)
- Beauty: 4 products (10%)
- Sports: 4 products (10%)
- Men's Clothing: 1 product (2.5%)
- Women's Clothing: 1 product (2.5%)

**Size Chart Templates:**
- Only 2 templates exist: "Men's Clothing Standard" and "Women's Clothing Standard"
- No templates for Electronics, Beauty, Home & Garden (which represent 60% of products)

### Current Code Structure

**Flutter App (`ecom_app/`):**
```
lib/features/
├── data/
│   ├── models/
│   │   ├── product_model.dart (has size chart fields)
│   │   └── size_chart_model.dart
│   └── repositories/
│       └── size_chart_repository.dart
├── presentation/
│   ├── widgets/
│   │   ├── size_chart_widget.dart
│   │   ├── size_chart_widget_simple.dart
│   │   └── pdp/color_size_selection.dart
│   └── screens/product/
│       └── real_enhanced_product_details_screen.dart
```

**Vendor Dashboard (`vendor-dashboard/`):**
```
src/app/(Tabs)/products/
├── components/form/
│   ├── ProductForm.jsx (6-step form)
│   └── steps/
│       ├── BasicInformationStep.jsx
│       ├── VariantsOptionsStep.jsx (handles sizes/colors)
│       └── [other steps]
└── create/page.jsx
```

## 🎯 Implementation Plan

## Phase 1: Database Schema Enhancement

### 1.1 Categories Table Enhancement
```sql
-- Add size chart configuration to categories
ALTER TABLE categories 
ADD COLUMN requires_size_chart BOOLEAN DEFAULT false,
ADD COLUMN default_size_chart_template_id UUID REFERENCES size_chart_templates(id),
ADD COLUMN size_chart_applicability TEXT CHECK (size_chart_applicability IN ('always', 'conditional', 'never')) DEFAULT 'never';

-- Add index for performance
CREATE INDEX idx_categories_size_chart_config ON categories(requires_size_chart, size_chart_applicability);
```

### 1.2 Products Table Enhancement
```sql
-- Add product-level size chart controls
ALTER TABLE products 
ADD COLUMN product_type TEXT,
ADD COLUMN sizing_required BOOLEAN DEFAULT false,
ADD COLUMN size_chart_override TEXT CHECK (size_chart_override IN ('show', 'hide', 'auto')) DEFAULT 'auto';

-- Add indexes
CREATE INDEX idx_products_size_chart_config ON products(sizing_required, size_chart_override);
CREATE INDEX idx_products_type ON products(product_type);
```

### 1.3 Vendor Size Chart Management Tables
```sql
-- Vendor-created size chart templates
CREATE TABLE vendor_size_chart_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  category_id UUID REFERENCES categories(id),
  subcategory VARCHAR(255),
  measurement_types JSONB NOT NULL,
  measurement_instructions TEXT,
  size_recommendations JSONB,
  chart_type VARCHAR(50) DEFAULT 'custom',
  template_data JSONB NOT NULL,
  approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES admin_users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Product size chart assignments tracking
CREATE TABLE product_size_chart_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  template_id UUID REFERENCES size_chart_templates(id),
  vendor_template_id UUID REFERENCES vendor_size_chart_templates(id),
  custom_data JSONB,
  assignment_type VARCHAR(20) NOT NULL CHECK (assignment_type IN ('admin_template', 'vendor_template', 'custom')),
  assigned_by UUID REFERENCES vendors(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Size chart usage analytics
CREATE TABLE size_chart_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id),
  template_id UUID REFERENCES size_chart_templates(id),
  vendor_template_id UUID REFERENCES vendor_size_chart_templates(id),
  user_id UUID REFERENCES auth.users(id),
  action_type VARCHAR(50) NOT NULL, -- 'viewed', 'size_selected', 'converted'
  selected_size VARCHAR(10),
  session_id VARCHAR(255),
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_vendor_templates_vendor ON vendor_size_chart_templates(vendor_id);
CREATE INDEX idx_vendor_templates_approval ON vendor_size_chart_templates(approval_status);
CREATE INDEX idx_product_assignments_product ON product_size_chart_assignments(product_id);
CREATE INDEX idx_size_chart_analytics_product ON size_chart_analytics(product_id);
CREATE INDEX idx_size_chart_analytics_action ON size_chart_analytics(action_type, created_at);
```

### 1.4 RLS Policies
```sql
-- Vendor size chart templates RLS
ALTER TABLE vendor_size_chart_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can view their own templates" ON vendor_size_chart_templates
  FOR SELECT USING (vendor_id = (SELECT id FROM vendors WHERE user_id = auth.uid()));

CREATE POLICY "Vendors can create their own templates" ON vendor_size_chart_templates
  FOR INSERT WITH CHECK (vendor_id = (SELECT id FROM vendors WHERE user_id = auth.uid()));

CREATE POLICY "Vendors can update their own pending templates" ON vendor_size_chart_templates
  FOR UPDATE USING (
    vendor_id = (SELECT id FROM vendors WHERE user_id = auth.uid()) 
    AND approval_status = 'pending'
  );

-- Product assignments RLS
ALTER TABLE product_size_chart_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can manage their product assignments" ON product_size_chart_assignments
  FOR ALL USING (
    assigned_by = (SELECT id FROM vendors WHERE user_id = auth.uid())
    OR product_id IN (SELECT id FROM products WHERE vendor_id = (SELECT id FROM vendors WHERE user_id = auth.uid()))
  );
```

## Phase 2: Flutter App Updates

### 2.1 Enhanced Size Chart Models
Update `lib/features/data/models/size_chart_model.dart`:

```dart
// Add to SizeChartModel class
class SizeChartModel {
  // ... existing fields
  final String? vendorId;
  final String approvalStatus;
  final String? rejectionReason;
  final bool isVendorTemplate;
  
  // Add factory constructor for vendor templates
  factory SizeChartModel.fromVendorTemplate(Map<String, dynamic> data) {
    return SizeChartModel(
      id: data['id'],
      name: data['name'],
      category: data['category'] ?? 'Custom',
      subcategory: data['subcategory'] ?? '',
      measurementTypes: List<String>.from(data['measurement_types'] ?? []),
      measurementInstructions: data['measurement_instructions'] ?? '',
      sizeRecommendations: Map<String, String>.from(data['size_recommendations'] ?? {}),
      chartType: data['chart_type'] ?? 'custom',
      isActive: data['is_active'] ?? true,
      vendorId: data['vendor_id'],
      approvalStatus: data['approval_status'] ?? 'pending',
      rejectionReason: data['rejection_reason'],
      isVendorTemplate: true,
      entries: (data['template_data']['entries'] as List<dynamic>? ?? [])
          .map((entry) => SizeChartEntry.fromMap(entry))
          .toList(),
    );
  }
}
```

### 2.2 Enhanced Size Chart Repository
Update `lib/features/data/repositories/size_chart_repository.dart`:

```dart
class SizeChartRepository {
  // ... existing methods

  /// Enhanced size chart selection with new rules
  Future<SizeChartModel?> getSizeChartForProduct(Product product) async {
    try {
      // Priority 1: Product explicit override
      if (product.sizeChartOverride == 'hide') return null;
      
      // Priority 2: Product has custom data
      if (product.sizeGuideType == 'custom' && product.customSizeChartData != null) {
        return SizeChartModel.fromCustomData(product.customSizeChartData!, product.name);
      }

      // Priority 3: Product assigned template
      if (product.sizeChartTemplateId != null) {
        return await getSizeChartTemplate(product.sizeChartTemplateId!);
      }

      // Priority 4: Check if product should have size chart
      if (!await _shouldShowSizeChart(product)) return null;

      // Priority 5: Category default template
      if (product.categoryId != null) {
        final categoryTemplate = await getSizeChartByCategory(product.categoryId!);
        if (categoryTemplate != null) return categoryTemplate;
      }

      // Priority 6: Legacy fallback
      return await getLegacyChartByCategory(product.categoryId);
    } catch (e) {
      print('Error fetching size chart: $e');
      return null;
    }
  }

  /// Determine if product should show size chart
  Future<bool> _shouldShowSizeChart(Product product) async {
    try {
      // Get category configuration
      final categoryConfig = await _supabase
          .from('categories')
          .select('requires_size_chart, size_chart_applicability')
          .eq('id', product.categoryId)
          .single();

      final applicability = categoryConfig['size_chart_applicability'] as String?;
      
      if (applicability == 'never') return false;
      if (applicability == 'always') return true;
      
      // Conditional logic
      return _evaluateConditionalRules(product);
    } catch (e) {
      return _evaluateConditionalRules(product);
    }
  }

  bool _evaluateConditionalRules(Product product) {
    // Electronics - only wearables
    if (_isElectronicsCategory(product.categoryId)) {
      return _isWearableElectronics(product.name);
    }
    
    // Clothing - if has meaningful sizes
    if (_isClothingCategory(product.categoryId)) {
      return product.sizes.length > 1 && !_hasGenericSizes(product.sizes);
    }
    
    // Beauty - only if has size variations
    if (_isBeautyCategory(product.categoryId)) {
      return _hasMeaningfulSizeVariations(product);
    }
    
    return false;
  }
}
```

### 2.3 Smart Size Chart Widget
Update `lib/features/presentation/widgets/size_chart_widget.dart`:

```dart
class SizeChartButton extends StatelessWidget {
  final Product product;
  final List<String> availableSizes;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowSizeChart(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }
        return _buildSizeChartButton();
      },
    );
  }

  Future<bool> _shouldShowSizeChart() async {
    final repository = Get.find<SizeChartRepository>();
    final sizeChart = await repository.getSizeChartForProduct(product);
    return sizeChart != null;
  }
}
```

## Phase 3: Vendor Dashboard Implementation

### 3.1 Size Chart Management Module Structure
```
src/app/(Tabs)/size-charts/
├── page.jsx                    # Size chart overview
├── templates/
│   ├── page.jsx               # Template library
│   ├── create/page.jsx        # Create custom template
│   └── [id]/page.jsx          # Edit template
├── products/
│   ├── page.jsx               # Product assignment management
│   └── bulk/page.jsx          # Bulk assignment
└── components/
    ├── TemplateLibrary.jsx
    ├── TemplateCreator.jsx
    ├── SizeChartPreview.jsx
    ├── ProductAssignment.jsx
    └── BulkManager.jsx
```

### 3.2 Size Chart Templates API
Create `src/app/api/size-chart-templates/route.js`:

```javascript
import { createClient } from '@/lib/supabase-server'

export async function GET(request) {
  const supabase = createClient()
  const { searchParams } = new URL(request.url)
  const categoryId = searchParams.get('category_id')
  const vendorId = searchParams.get('vendor_id')

  try {
    let query = supabase
      .from('size_chart_templates')
      .select(`
        *,
        categories(name),
        size_chart_entries(*)
      `)
      .eq('is_active', true)

    // Admin templates (approved) + vendor's own templates
    if (vendorId) {
      query = query.or(`category_id.is.null,vendor_id.eq.${vendorId}`)
    }

    if (categoryId) {
      query = query.eq('category_id', categoryId)
    }

    const { data, error } = await query.order('name')

    if (error) throw error

    return Response.json({ templates: data })
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 })
  }
}

export async function POST(request) {
  const supabase = createClient()
  const body = await request.json()

  try {
    // Create vendor template
    const { data: template, error: templateError } = await supabase
      .from('vendor_size_chart_templates')
      .insert({
        vendor_id: body.vendor_id,
        name: body.name,
        category_id: body.category_id,
        measurement_types: body.measurement_types,
        measurement_instructions: body.measurement_instructions,
        size_recommendations: body.size_recommendations,
        template_data: body.template_data
      })
      .select()
      .single()

    if (templateError) throw templateError

    return Response.json({ template })
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 })
  }
}
```

### 3.3 Template Creator Component
Create `src/app/(Tabs)/size-charts/components/TemplateCreator.jsx`:

```jsx
'use client'
import { useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'

export default function TemplateCreator({ onSave, onCancel }) {
  const { vendor } = useAuth()
  const [template, setTemplate] = useState({
    name: '',
    category_id: '',
    measurement_types: ['Chest', 'Length'],
    measurement_instructions: '',
    size_recommendations: {},
    entries: []
  })

  const [isSubmitting, setIsSubmitting] = useState(false)

  const addSizeEntry = () => {
    const newEntry = {
      size: '',
      measurements: {}
    }
    
    template.measurement_types.forEach(type => {
      newEntry.measurements[type] = { cm: 0, inches: 0 }
    })

    setTemplate(prev => ({
      ...prev,
      entries: [...prev.entries, newEntry]
    }))
  }

  const updateSizeEntry = (index, field, value) => {
    setTemplate(prev => ({
      ...prev,
      entries: prev.entries.map((entry, i) => 
        i === index ? { ...entry, [field]: value } : entry
      )
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsSubmitting(true)

    try {
      const response = await fetch('/api/size-chart-templates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...template,
          vendor_id: vendor.id,
          template_data: { entries: template.entries }
        })
      })

      if (!response.ok) throw new Error('Failed to create template')

      const result = await response.json()
      onSave(result.template)
    } catch (error) {
      console.error('Error creating template:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Template Basic Info */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Template Information</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Template Name</label>
              <input
                type="text"
                value={template.name}
                onChange={(e) => setTemplate(prev => ({ ...prev, name: e.target.value }))}
                className="w-full p-3 border rounded-lg"
                placeholder="e.g., My Custom Shirt Sizes"
                required
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">Category</label>
              <select
                value={template.category_id}
                onChange={(e) => setTemplate(prev => ({ ...prev, category_id: e.target.value }))}
                className="w-full p-3 border rounded-lg"
                required
              >
                <option value="">Select Category</option>
                {/* Categories will be loaded dynamically */}
              </select>
            </div>
          </div>

          <div className="mt-4">
            <label className="block text-sm font-medium mb-2">Measurement Instructions</label>
            <textarea
              value={template.measurement_instructions}
              onChange={(e) => setTemplate(prev => ({ ...prev, measurement_instructions: e.target.value }))}
              className="w-full p-3 border rounded-lg h-24"
              placeholder="Provide clear instructions on how to measure..."
            />
          </div>
        </div>

        {/* Measurement Types */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Measurement Types</h3>
          
          <div className="flex flex-wrap gap-2 mb-4">
            {template.measurement_types.map((type, index) => (
              <div key={index} className="flex items-center bg-blue-100 rounded-lg px-3 py-2">
                <input
                  type="text"
                  value={type}
                  onChange={(e) => {
                    const newTypes = [...template.measurement_types]
                    newTypes[index] = e.target.value
                    setTemplate(prev => ({ ...prev, measurement_types: newTypes }))
                  }}
                  className="bg-transparent border-none outline-none text-sm"
                />
                <button
                  type="button"
                  onClick={() => {
                    const newTypes = template.measurement_types.filter((_, i) => i !== index)
                    setTemplate(prev => ({ ...prev, measurement_types: newTypes }))
                  }}
                  className="ml-2 text-red-500 hover:text-red-700"
                >
                  ×
                </button>
              </div>
            ))}
            
            <button
              type="button"
              onClick={() => setTemplate(prev => ({ 
                ...prev, 
                measurement_types: [...prev.measurement_types, 'New Measurement'] 
              }))}
              className="px-3 py-2 border-2 border-dashed border-gray-300 rounded-lg text-sm text-gray-500 hover:border-blue-500 hover:text-blue-500"
            >
              + Add Measurement Type
            </button>
          </div>
        </div>

        {/* Size Entries */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold">Size Chart Data</h3>
            <button
              type="button"
              onClick={addSizeEntry}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Add Size
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full border-collapse border border-gray-300">
              <thead>
                <tr className="bg-gray-50">
                  <th className="border border-gray-300 p-3 text-left">Size</th>
                  {template.measurement_types.map(type => (
                    <th key={type} className="border border-gray-300 p-3 text-center">
                      {type} (cm)
                    </th>
                  ))}
                  <th className="border border-gray-300 p-3 text-center">Actions</th>
                </tr>
              </thead>
              <tbody>
                {template.entries.map((entry, index) => (
                  <tr key={index}>
                    <td className="border border-gray-300 p-3">
                      <input
                        type="text"
                        value={entry.size}
                        onChange={(e) => updateSizeEntry(index, 'size', e.target.value)}
                        className="w-full p-2 border rounded"
                        placeholder="S, M, L..."
                      />
                    </td>
                    {template.measurement_types.map(type => (
                      <td key={type} className="border border-gray-300 p-3">
                        <input
                          type="number"
                          value={entry.measurements[type]?.cm || ''}
                          onChange={(e) => {
                            const cm = parseFloat(e.target.value) || 0
                            const inches = cm / 2.54
                            updateSizeEntry(index, 'measurements', {
                              ...entry.measurements,
                              [type]: { cm, inches }
                            })
                          }}
                          className="w-full p-2 border rounded text-center"
                          placeholder="0"
                        />
                      </td>
                    ))}
                    <td className="border border-gray-300 p-3 text-center">
                      <button
                        type="button"
                        onClick={() => {
                          setTemplate(prev => ({
                            ...prev,
                            entries: prev.entries.filter((_, i) => i !== index)
                          }))
                        }}
                        className="text-red-500 hover:text-red-700"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Submit Buttons */}
        <div className="flex justify-end space-x-4">
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            {isSubmitting ? 'Creating...' : 'Create Template'}
          </button>
        </div>
      </form>
    </div>
  )
}
```

### 3.4 Product Form Integration
Update `src/app/(Tabs)/products/components/form/steps/VariantsOptionsStep.jsx`:

```jsx
// Add size chart section
const SizeChartSection = ({ formData, onUpdate }) => {
  const [templates, setTemplates] = useState([])
  const [showCustomCreator, setShowCustomCreator] = useState(false)

  useEffect(() => {
    loadTemplates()
  }, [formData.category])

  const loadTemplates = async () => {
    try {
      const response = await fetch(`/api/size-chart-templates?category_id=${formData.category}`)
      const data = await response.json()
      setTemplates(data.templates || [])
    } catch (error) {
      console.error('Error loading templates:', error)
    }
  }

  return (
    <div className="space-y-4">
      <h4 className="font-medium">Size Chart Configuration</h4>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label className="block text-sm font-medium mb-2">Size Guide Type</label>
          <select
            value={formData.size_guide_type || 'none'}
            onChange={(e) => onUpdate('size_guide_type', e.target.value)}
            className="w-full p-3 border rounded-lg"
          >
            <option value="none">No Size Chart</option>
            <option value="template">Use Template</option>
            <option value="custom">Custom Size Chart</option>
          </select>
        </div>

        {formData.size_guide_type === 'template' && (
          <div>
            <label className="block text-sm font-medium mb-2">Select Template</label>
            <select
              value={formData.size_chart_template_id || ''}
              onChange={(e) => onUpdate('size_chart_template_id', e.target.value)}
              className="w-full p-3 border rounded-lg"
            >
              <option value="">Choose Template</option>
              {templates.map(template => (
                <option key={template.id} value={template.id}>
                  {template.name}
                </option>
              ))}
            </select>
          </div>
        )}

        <div className="flex items-end">
          <button
            type="button"
            onClick={() => setShowCustomCreator(true)}
            className="px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Create Custom Template
          </button>
        </div>
      </div>

      {/* Template Preview */}
      {formData.size_chart_template_id && (
        <div className="p-4 bg-gray-50 rounded-lg">
          <h5 className="font-medium mb-2">Template Preview</h5>
          {/* Template preview component */}
        </div>
      )}
    </div>
  )
}
```

## Phase 4: Admin Dashboard Integration

### 4.1 Admin Size Chart Management
Add to admin dashboard:

```
admin-dashboard/src/pages/
├── size-charts/
│   ├── index.jsx              # Overview & analytics
│   ├── templates.jsx          # Manage admin templates
│   ├── vendor-requests.jsx    # Approve vendor templates
│   └── analytics.jsx          # Usage analytics
```

### 4.2 Vendor Template Approval API
Create `src/app/api/admin/size-chart-templates/route.js`:

```javascript
export async function PATCH(request) {
  const supabase = createClient()
  const { templateId, action, rejectionReason } = await request.json()

  try {
    const updateData = {
      approval_status: action, // 'approved' or 'rejected'
      approved_at: action === 'approved' ? new Date().toISOString() : null,
      rejection_reason: action === 'rejected' ? rejectionReason : null
    }

    const { data, error } = await supabase
      .from('vendor_size_chart_templates')
      .update(updateData)
      .eq('id', templateId)
      .select()
      .single()

    if (error) throw error

    return Response.json({ template: data })
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 })
  }
}
```

## Phase 5: Data Migration & Initial Setup

### 5.1 Category Configuration Script
```sql
-- Configure existing categories
UPDATE categories SET 
  requires_size_chart = true,
  size_chart_applicability = 'conditional'
WHERE name IN ('Men''s Clothing', 'Women''s Clothing', 'Fashion', 'Sports');

UPDATE categories SET 
  requires_size_chart = false,
  size_chart_applicability = 'never'
WHERE name IN ('Electronics', 'Beauty', 'Home & Garden');

UPDATE categories SET 
  requires_size_chart = true,
  size_chart_applicability = 'conditional'
WHERE name = 'Accessories';
```

### 5.2 Product Classification Script
```sql
-- Classify existing products
UPDATE products SET 
  product_type = 'clothing',
  sizing_required = true
WHERE category_id IN (
  SELECT id FROM categories 
  WHERE name IN ('Men''s Clothing', 'Women''s Clothing', 'Fashion')
);

UPDATE products SET 
  product_type = 'electronics',
  sizing_required = false,
  size_chart_override = 'hide'
WHERE category_id IN (
  SELECT id FROM categories WHERE name = 'Electronics'
) AND NOT (
  LOWER(name) LIKE '%watch%' OR 
  LOWER(name) LIKE '%band%' OR 
  LOWER(name) LIKE '%strap%'
);

UPDATE products SET 
  product_type = 'footwear',
  sizing_required = true
WHERE category_id IN (
  SELECT id FROM categories WHERE name = 'Sports'
) AND (
  LOWER(name) LIKE '%shoe%' OR 
  LOWER(name) LIKE '%sneaker%' OR 
  LOWER(name) LIKE '%boot%'
);
```

### 5.3 Create Additional Templates
```sql
-- Footwear template
INSERT INTO size_chart_templates (name, category_id, measurement_types, measurement_instructions, size_recommendations, chart_type) 
VALUES (
  'Footwear Standard',
  (SELECT id FROM categories WHERE name = 'Sports'),
  '["Foot Length", "Foot Width"]',
  'Measure your foot from heel to longest toe. For width, measure the widest part of your foot.',
  '{"7": "US 7 - Foot length: 9.5-9.75 inches", "8": "US 8 - Foot length: 9.75-10 inches", "9": "US 9 - Foot length: 10-10.25 inches"}',
  'footwear'
);

-- Accessories template
INSERT INTO size_chart_templates (name, category_id, measurement_types, measurement_instructions, size_recommendations, chart_type) 
VALUES (
  'Accessories Standard',
  (SELECT id FROM categories WHERE name = 'Accessories'),
  '["Circumference", "Length"]',
  'For rings: measure inside diameter. For bracelets: measure wrist circumference.',
  '{"S": "Small - 6-7 inch wrist", "M": "Medium - 7-8 inch wrist", "L": "Large - 8-9 inch wrist"}',
  'accessories'
);
```

## Phase 6: Testing & Validation

### 6.1 Test Cases
```javascript
// Test size chart visibility rules
describe('Size Chart Visibility', () => {
  test('should hide size chart for electronics', () => {
    const product = { category: 'Electronics', name: 'Smartphone' }
    expect(shouldShowSizeChart(product)).toBe(false)
  })

  test('should show size chart for clothing with multiple sizes', () => {
    const product = { 
      category: 'Men\'s Clothing', 
      name: 'T-Shirt',
      sizes: ['S', 'M', 'L'] 
    }
    expect(shouldShowSizeChart(product)).toBe(true)
  })

  test('should show size chart for wearable electronics', () => {
    const product = { 
      category: 'Electronics', 
      name: 'Smartwatch',
      sizes: ['38mm', '42mm'] 
    }
    expect(shouldShowSizeChart(product)).toBe(true)
  })
})
```

### 6.2 Performance Monitoring
```sql
-- Monitor size chart usage
SELECT 
  p.name as product_name,
  c.name as category_name,
  COUNT(sca.id) as views,
  COUNT(CASE WHEN sca.action_type = 'size_selected' THEN 1 END) as selections,
  COUNT(CASE WHEN sca.action_type = 'converted' THEN 1 END) as conversions
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN size_chart_analytics sca ON p.id = sca.product_id
WHERE sca.created_at >= NOW() - INTERVAL '30 days'
GROUP BY p.id, p.name, c.name
ORDER BY views DESC;
```

## 🚀 Deployment Checklist

### Database Migration
- [ ] Run schema updates on staging
- [ ] Test RLS policies
- [ ] Run data migration scripts
- [ ] Verify indexes are created

### Flutter App
- [ ] Update size chart models
- [ ] Deploy enhanced repository logic
- [ ] Test size chart visibility rules
- [ ] Update UI components

### Vendor Dashboard
- [ ] Deploy size chart management pages
- [ ] Test template creation flow
- [ ] Verify product assignment works
- [ ] Test bulk operations

### Admin Dashboard
- [ ] Add template approval interface
- [ ] Test vendor template review
- [ ] Verify analytics tracking

### Testing
- [ ] Run automated tests
- [ ] Manual testing across categories
- [ ] Performance testing
- [ ] User acceptance testing

## 📊 Success Metrics

### Immediate (Week 1-2)
- [ ] 95% reduction in irrelevant size charts shown
- [ ] All clothing products have appropriate size charts
- [ ] Electronics products hide size charts (except wearables)

### Short-term (Month 1)
- [ ] 50% of vendors create custom templates
- [ ] 80% improvement in size chart relevance
- [ ] 25% increase in size chart usage

### Long-term (Month 3)
- [ ] 15% increase in conversion rate for sized products
- [ ] 30% reduction in size-related returns
- [ ] 90% vendor satisfaction with size chart tools

## 🔧 Maintenance & Monitoring

### Weekly Tasks
- Review vendor template submissions
- Monitor size chart analytics
- Check for new product categories needing templates

### Monthly Tasks
- Analyze size chart effectiveness
- Update templates based on feedback
- Review and optimize database performance

### Quarterly Tasks
- Comprehensive system review
- Update size chart rules based on new product types
- Vendor feedback collection and implementation

---

**Implementation Timeline: 6-8 weeks**
**Priority: High (addresses major UX issue)**
**Complexity: Medium-High**
**Dependencies: Database migration, Flutter updates, Dashboard updates**
