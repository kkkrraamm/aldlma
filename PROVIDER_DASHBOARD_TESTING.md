# Provider Dashboard - Quick Testing Guide 🧪

## How to Test the Provider Dashboard

### Prerequisites
- Provider request status must be `'approved'` in database
- User must be logged in
- User must have valid JWT token

### Test Flow

#### Step 1: Navigate to My Account Page
```
Bottom Navigation → My Account (أكاونتي)
```

#### Step 2: Scroll Down to Requests Section
You should see two request tiles:
- Media Request (إعلامي)
- Provider Request (مقدم خدمة)

#### Step 3: Check Provider Request Status
Look for the status badge on the Provider Request tile:
- ❌ Pending: "قيد المراجعة" (grey)
- ✅ Approved: "موافق عليه" (green)
- ❌ Rejected: "مرفوض" (red)

#### Step 4: Approve Provider Request (Admin Action Required)
If status is "قيد المراجعة" (pending):
1. Go to admin panel
2. Find the provider request
3. Click "Approve Request" (الموافقة على الطلب)
4. Notification will be sent to user

#### Step 5: Refresh My Account Page
- Pull to refresh, or
- Navigate away and back to My Account

#### Step 6: Look for the Provider Dashboard Button
When status is "موافق عليه" (approved), you should see:
```
┌──────────────────────────┐
│ انتقال إلى متجري 🏪      │ ← NEW BUTTON
└──────────────────────────┘
```

The button should appear below the provider request status.

#### Step 7: Click the Button
Tap "انتقال إلى متجري" button

#### Step 8: Provider Dashboard Opens
You should see:
- Loading indicator (briefly)
- Dashboard header with store info
- 5 tabs: نظرة عامة | المنتجات | الفيديوهات | العروض | الإحصائيات

---

## Testing Checklist

### Visual Tests
- [ ] Button appears only when status is approved
- [ ] Button has correct color (gold/green)
- [ ] Button has correct icon (🏪)
- [ ] Button text is in Arabic
- [ ] Button is clickable

### Navigation Tests
- [ ] Clicking button navigates to dashboard
- [ ] Dashboard loads with header
- [ ] All 5 tabs are visible
- [ ] Tabs are clickable
- [ ] Back button works (navigates back to My Account)

### Tab Tests

#### Overview Tab
- [ ] 4 stat cards visible (sales, revenue, products, videos)
- [ ] Stats display correctly
- [ ] 3 quick action cards visible
- [ ] Action cards are clickable (show toast)

#### Products Tab
- [ ] Empty state shows if no products
- [ ] Products list shows if available
- [ ] Each product shows name and price
- [ ] Edit button is present
- [ ] FAB shows "إضافة منتج" on this tab

#### Videos Tab
- [ ] Empty state shows if no videos
- [ ] Videos display in 2-column grid if available
- [ ] Each video shows thumbnail, title, views, likes
- [ ] FAB shows "رفع فيديو" on this tab

#### Promotions Tab
- [ ] Empty state shows
- [ ] Action button says "إنشاء عرض"
- [ ] Clicking shows toast: "صفحة العروض قريباً"
- [ ] FAB shows "إنشاء عرض" on this tab

#### Analytics Tab
- [ ] Line chart displays
- [ ] Top 3 products show with rank, name, sales, revenue
- [ ] Data is formatted correctly

### Theme Tests
- [ ] Dark mode: Colors look correct (gold theme)
- [ ] Light mode: Colors look correct (green theme)
- [ ] Text is readable in both modes
- [ ] Icons are visible in both modes

### Responsive Tests
- [ ] Landscape mode works
- [ ] Portrait mode works
- [ ] All content fits on screen
- [ ] No overflow errors
- [ ] Spacing looks consistent

### Error Handling
- [ ] If no store data, shows "لم يتم إنشاء المتجر بعد"
- [ ] If token expired, shows appropriate message
- [ ] Network errors handled gracefully
- [ ] Loading state shows during data fetch

### Performance Tests
- [ ] Dashboard loads quickly (< 2 seconds)
- [ ] Tab switching is smooth
- [ ] No lag when scrolling
- [ ] Memory usage is reasonable
- [ ] No crashes or freezes

---

## Troubleshooting

### Button Doesn't Appear
**Problem**: "انتقال إلى متجري" button not showing
- **Check**: Is provider request status really 'approved'?
- **Check**: Database value for status field
- **Check**: Refresh the page (hot reload)
- **Check**: Clear SharedPreferences cache

### Dashboard Won't Load
**Problem**: Blank screen or loading forever
- **Check**: Is token valid and not expired?
- **Check**: Is API `/provider/store` endpoint working?
- **Check**: Check network connectivity
- **Check**: Check browser console for errors (web)
- **Check**: Check Android/iOS logs (mobile)

### Wrong Colors in Dashboard
**Problem**: Colors don't match Dalma theme
- **Check**: ThemeConfig.isDarkMode value
- **Check**: Is theme switching working elsewhere?
- **Check**: Restart app (hot restart, not just reload)

### Tab Content Not Showing
**Problem**: Tab bar visible but content is blank
- **Check**: Ensure list/grid data is being loaded
- **Check**: Check for API errors in console
- **Check**: Verify _OverviewTab/_ProductsTab are built
- **Check**: No exception in try-catch blocks

### Button Styling Wrong
**Problem**: Button looks different than expected
- **Check**: Google Fonts Cairo is loaded
- **Check**: ThemeConfig colors are correct
- **Check**: All required imports are present
- **Check**: No CSS/theme override issues

---

## API Endpoints to Mock (For Testing)

```json
GET /api/provider/store
Authorization: Bearer <token>

Response:
{
  "store": {
    "id": 1,
    "store_name": "متجري الرائع",
    "store_logo": "https://...",
    "is_verified": true,
    "rating": 4.8,
    "followers_count": 150,
    "total_sales": 45,
    "total_revenue": 500000,
    "products_count": 10,
    "videos_count": 5
  },
  "products": [
    {
      "id": 1,
      "name_ar": "iPhone 15",
      "price": 3999
    }
  ],
  "videos": [
    {
      "id": 1,
      "title": "فيديو المنتج",
      "views_count": 250,
      "likes_count": 50
    }
  ]
}
```

---

## Test Data

### In Android Emulator:
1. Clear app data
2. Login with test account
3. Go to admin panel
4. Create and approve provider request
5. Test the dashboard

### In iOS Simulator:
Same steps as Android

### On Web:
1. Open DevTools
2. Clear localStorage
3. Test API calls in Network tab
4. Check console for errors

---

## Expected Behavior

### First Time Opening Dashboard
- [ ] Shows loading spinner
- [ ] Fetches data from API
- [ ] Displays store header
- [ ] Shows all 5 tabs
- [ ] Default tab is "Overview"

### After Data Loads
- [ ] Overview tab shows statistics
- [ ] Products tab shows list or empty state
- [ ] Videos tab shows grid or empty state
- [ ] Promotions tab shows empty state
- [ ] Analytics tab shows chart

### User Interactions
- [ ] Can switch between tabs smoothly
- [ ] Quick action cards show toast on tap
- [ ] Edit buttons show toast on tap
- [ ] FAB changes per tab
- [ ] Back button returns to My Account

---

## Performance Benchmarks

| Metric | Expected | Accept |
|--------|----------|--------|
| Initial Load | < 1s | < 2s |
| Tab Switch | < 200ms | < 500ms |
| Data Refresh | < 1.5s | < 2.5s |
| Memory Usage | < 50MB | < 100MB |
| FPS | 60fps | > 30fps |

---

## Success Criteria

✅ All tests pass
✅ No errors in logs
✅ App doesn't crash
✅ Performance is acceptable
✅ UI matches Dalma design
✅ Arabic text displays correctly
✅ Both themes work properly
✅ Navigation flows smoothly

---

**Testing Status**: Ready for QA ✅
**Date**: November 22, 2024
