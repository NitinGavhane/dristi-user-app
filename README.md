# dristi-user-app

A Flutter-based dristi mobile application with a professional design system, mock data, and comprehensive UI screens. Built as the mobile frontend for the **Garment E-commerce Platform**.

## Tech Stack

- **Flutter** 3.1+ with Dart
- **Google Fonts** (Poppins)
- **Iconsax** icon pack
- **Provider** for state management
- **intl** for formatting

## Project Structure

```
apps/mobile/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # 30+ color tokens (primary, secondary, gradients, semantic)
│   │   │   ├── app_text_styles.dart    # Typography scale using Poppins
│   │   │   └── app_dimensions.dart     # Spacing & sizing scale
│   │   ├── theme/
│   │   │   └── app_theme.dart          # Material 3 theme (buttons, inputs, cards, nav bar)
│   │   └── widgets/
│   │       ├── app_button.dart         # Filled/outlined/loading button states
│   │       ├── app_text_field.dart     # Form inputs with password toggle & validation
│   │       ├── product_card.dart       # Product grid card (gradient, badge, wishlist)
│   │       └── category_card.dart      # Category icon grid item
│   ├── models/
│   │   ├── product.dart
│   │   ├── category.dart
│   │   ├── cart_item.dart
│   │   ├── order.dart
│   │   ├── address.dart
│   │   └── user.dart
│   ├── mock/
│   │   └── mock_data.dart              # 16 products, 8 categories, 4 orders, sample addresses
│   ├── features/
│   │   ├── auth/screens/               # Login & Register
│   │   ├── home/screens/ & widgets/    # Home (carousel, categories, featured)
│   │   ├── product/screens/            # Product List & Detail
│   │   ├── cart/screens/               # Cart
│   │   ├── checkout/screens/           # Checkout
│   │   ├── orders/screens/ & widgets/  # Orders List & Order Detail (tracking timeline)
│   │   ├── profile/screens/            # Profile
│   │   ├── wishlist/screens/           # Wishlist
│   │   └── search/screens/             # Search
│   ├── routes/
│   │   └── app_routes.dart             # Named routes + MainShell (bottom nav)
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Screens

| Screen | Features |
|---|---|
| **Login** | Email/password form, social buttons (Google/OTP), register navigation |
| **Register** | Name, email, phone, password with validation |
| **Home** | Search bar, banner carousel, category grid, featured + new arrivals |
| **Product List** | Grid with sort (5 options) & filter (size, color, price) bottom sheets |
| **Product Detail** | Gradient hero image, size/color selection, reviews, sticky bottom bar |
| **Cart** | Swipe-to-delete, quantity controls, subtotal/shipping/total summary |
| **Checkout** | Address picker, 7 payment methods, item summary, order placed modal |
| **Orders** | Filter tabs (All/Active/Shipped/Delivered/Cancelled) |
| **Order Detail** | 6-step tracking timeline, items, address, price breakdown |
| **Profile** | Avatar, stats, settings menu, sign out |
| **Wishlist** | Grid with remove capability |
| **Search** | Recent searches, popular categories, real-time results |

## Navigation

Bottom navigation bar with 4 tabs: **Home**, **Cart**, **Orders**, **Profile**.

## Getting Started

```bash
# Navigate to the app directory
cd apps/mobile

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Dependencies

- `google_fonts` — Poppins typography
- `iconsax` — Icon set
- `provider` — State management
- `badges` — Notification badge widget
- `shimmer` — Loading placeholders
- `intl` — Date & number formatting

## Architecture

The app follows a **feature-first** folder structure with a shared **core** layer for the design system and reusable widgets. All data is currently served from `mock_data.dart` — no backend or database integration.

## Related Repositories

- **Backend API**: Python FastAPI
- **Web Platform**: React.js / Next.js
- **Database**: PostgreSQL

## License

Proprietary — Garment E-commerce Platform
