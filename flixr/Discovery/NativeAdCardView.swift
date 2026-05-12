import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - UIKit native ad view
//
// Layout: media occupies the top 58% of the card; headline/body/CTA occupy
// the dark panel below. No registered asset view overlaps another, which is
// required by AdMob policy ("Assets can not be placed on top of another asset").
//
//  ┌──────────────────────┐
//  │ [Ad]    AdChoices→   │
//  │                      │
//  │      MediaView       │  58%  contentMode = .scaleAspectFit (no vertical crop)
//  │                      │
//  ├──────────────────────┤
//  │  [icon] (if present) │
//  │  Headline (2 lines)  │  42%
//  │  Body    (2 lines)   │
//  │  [ CTA Button ]      │
//  └──────────────────────┘

final class FlixrNativeAdView: NativeAdView {
    private let adMediaView    = MediaView()
    private let separator      = UIView()
    private let badgeLabel     = UILabel()
    private let iconImageView  = UIImageView()
    private let headlineLabel  = UILabel()
    private let bodyLabel      = UILabel()
    private let ctaButton      = UIButton(type: .system)

    // Toggled in populate() depending on whether an icon was provided
    private var headlineTopToSeparator: NSLayoutConstraint!
    private var headlineTopToIcon: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = UIColor(white: 0.07, alpha: 1)
        clipsToBounds = true
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous

        // Media — top 58%.
        // .scaleAspectFit: never crops vertically (policy violation if cropped).
        adMediaView.contentMode = .scaleAspectFit
        adMediaView.clipsToBounds = true
        adMediaView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adMediaView)

        // Separator
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        // "Ad" badge — required, min 15×15pt. 32×22pt satisfies this.
        // Positioned top-left away from AdChoices (which renders top-right by default).
        badgeLabel.text = "Ad"
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = UIColor(red: 0.78, green: 0.09, blue: 0.18, alpha: 0.9)
        badgeLabel.layer.cornerRadius = 5
        badgeLabel.layer.masksToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeLabel)

        // App icon — required for app install ads when provided.
        // Hidden by default; shown in populate() when nativeAd.icon != nil.
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 8
        iconImageView.layer.masksToBounds = true
        iconImageView.isHidden = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        // Headline — 2 lines (policy: no truncation < 25 chars)
        headlineLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headlineLabel)

        // Body — 2 lines (policy: no truncation < 90 chars; 1 line at 13pt ≈ 40 chars)
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)

        // CTA button
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor(red: 0.78, green: 0.09, blue: 0.18, alpha: 1)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .medium
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return a
        }
        ctaButton.configuration = cfg
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ctaButton)

        // Register asset views — none of these overlap each other
        mediaView        = adMediaView
        iconView         = iconImageView
        headlineView     = headlineLabel
        bodyView         = bodyLabel
        callToActionView = ctaButton

        // Headline has two possible top anchors depending on whether an icon is shown
        headlineTopToSeparator = headlineLabel.topAnchor.constraint(
            equalTo: separator.bottomAnchor, constant: 14)
        headlineTopToIcon = headlineLabel.topAnchor.constraint(
            equalTo: iconImageView.bottomAnchor, constant: 8)

        NSLayoutConstraint.activate([
            // Media: top 58%
            adMediaView.topAnchor.constraint(equalTo: topAnchor),
            adMediaView.leadingAnchor.constraint(equalTo: leadingAnchor),
            adMediaView.trailingAnchor.constraint(equalTo: trailingAnchor),
            adMediaView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.58),

            // Separator
            separator.topAnchor.constraint(equalTo: adMediaView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            // Ad badge — top-left, away from AdChoices (top-right)
            badgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            badgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            badgeLabel.widthAnchor.constraint(equalToConstant: 32),
            badgeLabel.heightAnchor.constraint(equalToConstant: 22),

            // Icon — top of text panel, hidden until populate() shows it
            iconImageView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),

            // Headline — active top constraint set in populate()
            headlineTopToSeparator,
            headlineLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            headlineLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),

            // Body — below headline, 2 lines
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),

            // CTA — bottom of card, at least 10pt below body
            ctaButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            ctaButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            ctaButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            ctaButton.heightAnchor.constraint(equalToConstant: 44),
            ctaButton.topAnchor.constraint(greaterThanOrEqualTo: bodyLabel.bottomAnchor, constant: 10),
        ])
    }

    func populate(with nativeAd: NativeAd) {
        // Set nativeAd only after all asset views are registered (done in setup())
        self.nativeAd = nativeAd

        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body ?? nativeAd.advertiser
        ctaButton.setTitle(nativeAd.callToAction ?? "Learn More", for: .normal)
        adMediaView.mediaContent = nativeAd.mediaContent

        // Show icon for app install ads; hide for content ads
        if let icon = nativeAd.icon {
            iconImageView.image = icon.image
            iconImageView.isHidden = false
            headlineTopToSeparator.isActive = false
            headlineTopToIcon.isActive = true
        } else {
            iconImageView.isHidden = true
            headlineTopToIcon.isActive = false
            headlineTopToSeparator.isActive = true
        }
    }
}

// MARK: - SwiftUI wrapper

struct NativeAdCardView: UIViewRepresentable {
    let nativeAd: NativeAd
    let width: CGFloat
    let height: CGFloat

    func makeUIView(context: Context) -> FlixrNativeAdView {
        let view = FlixrNativeAdView()
        view.populate(with: nativeAd)
        return view
    }

    func updateUIView(_ uiView: FlixrNativeAdView, context: Context) {
        uiView.populate(with: nativeAd)
    }
}
