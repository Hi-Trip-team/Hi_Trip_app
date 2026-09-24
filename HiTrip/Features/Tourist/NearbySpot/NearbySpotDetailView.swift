import SwiftUI
import MapKit
import UIKit

// MARK: - NearbySpotDetailView
/// 스팟 상세
///
/// 서버가 주지 않는 값(별점·영업시간·거리)은 nil이면 해당 UI를 숨깁니다.
/// 어드벤티지(혜택)는 API 자체가 없어 아직 표시하지 못합니다.

struct NearbySpotDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var name: String
    var address: String?
    /// 지번 주소 — 도로명 주소(address) 아래에 작게 (카카오 장소 정보)
    var subAddress: String? = nil
    var description: String?
    /// 서버가 주지 않는 값들 — nil이면 해당 UI를 숨깁니다.
    var distance: String?
    var hours: String?
    var rating: Double?
    var reviewCount: Int?
    var imageUrl: String?
    /// 사진 여러 장 — 서버는 아직 image_url 한 장만 줍니다
    var imageUrls: [String] = []
    /// 광고 뱃지 — 전 지면 공통으로 is_sponsored 하나만 봅니다
    var isSponsored: Bool = false
    var latitude: Double?
    var longitude: Double?
    var tags: [String] = []
    /// 이미지가 없을 때 보여줄 대체 아이콘 선택에 사용
    var categoryName: String?
    /// 전화번호 — 카카오 장소 검색 결과에 있으면 탭해서 전화
    var phone: String?
    /// 카카오맵 장소 페이지 — 사진·리뷰·영업시간은 여기서 봅니다
    var placeUrl: String?
    /// 안내사 추천 이유 — 추천 스팟에만 있음
    var reason: String?

    /// 좌표가 없으면 지도 섹션을 숨깁니다.
    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    @State private var photoIndex = 0
    @State private var toast: String?
    @State private var showRouteOptions = false

    /// 표시할 사진들 — 없으면 대체 썸네일 1장
    private var photos: [String] {
        if !imageUrls.isEmpty { return imageUrls }
        if let imageUrl, !imageUrl.isEmpty { return [imageUrl] }
        return []
    }


    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                VStack(spacing: 0) {
                    thumbnailSection
                    infoSection
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                    Divider()
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    // 소개글이 없으면(카카오 검색 장소는 대부분 없음) 구분선도 함께 숨깁니다
                    if let description, !description.isEmpty {
                        descriptionSection
                            .padding(.horizontal, AppSpacing.lg)
                        Divider()
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                    }
                    mapPreviewSection
                        .padding(.horizontal, AppSpacing.lg)
                    Spacer().frame(height: 32)
                }
            }

            bottomButton
        }
        .background(Color.white)
        .toast($toast, inset: 90)
        .animation(.easeInOut(duration: 0.2), value: toast)
        .navigationBarHidden(true)
        .confirmationDialog("길찾기", isPresented: $showRouteOptions, titleVisibility: .visible) {
            // 기본 지도 앱(애플 지도)을 항상 먼저 제공합니다 — App Store 가이드라인 4
            Button("지도") { openRoute(.apple) }
            Button("카카오맵") { openRoute(.kakao) }
            Button("구글 지도") { openRoute(.google) }
            Button("취소", role: .cancel) { }
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        NavigationHeader(title: name, horizontalInset: AppSpacing.md) { dismiss() }
    }

    // MARK: - 썸네일

    private var thumbnailSection: some View {
        ZStack(alignment: .topLeading) {
            if photos.count > 1 {
                TabView(selection: $photoIndex) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, url in
                        SpotImageView(imageUrl: url, categoryName: categoryName, iconSize: 52)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 200)
            } else {
                // 사진이 없으면 카테고리 기본 썸네일 한 장
                SpotImageView(imageUrl: photos.first, categoryName: categoryName, iconSize: 52)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
            }

            if isSponsored {
                Text("광고")
                    .font(AppFont.microMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xs)
                    .frame(height: 20)
                    .background(AppColor.ink)
                    .cornerRadius(4)
                    .padding(AppSpacing.sm)
            }
        }
    }

    // MARK: - 기본 정보

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Text(name)
                    .font(AppFont.title2Bold)
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                if let rating {
                    Image(systemName: "star.fill")
                        .font(AppFont.label)
                        .foregroundColor(AppColor.warningAmber)
                    Text(String(format: "%.1f", rating))
                        .font(AppFont.labelBold)
                        .foregroundColor(AppColor.textPrimary)
                    if let reviewCount {
                        Text("(\(reviewCount))")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.textTertiary)
                    }
                }
            }

            if let address, !address.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.textSecondary)
                    Text(address)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.textSecondary)

                    Button {
                        UIPasteboard.general.string = address
                        toast = "주소가 복사되었어요"
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                                .font(AppFont.micro)
                            Text("복사")
                                .font(AppFont.caption2Medium)
                        }
                        .foregroundColor(AppColor.accent)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 지번 주소 — 도로명과 다를 때만
            if let subAddress, !subAddress.isEmpty, subAddress != address {
                Text("지번 \(subAddress)")
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textTertiary)
                    .padding(.leading, 20)
            }

            // 카테고리 — "음식점 > 구내식당"처럼 오면 마지막 단계만
            if let category = categoryName?.components(separatedBy: ">").last?
                .trimmingCharacters(in: .whitespaces), !category.isEmpty {
                infoChip(icon: "tag", text: category, color: AppColor.textSecondary)
            }

            // 전화 — 번호가 있을 때만
            if let phone, let url = AppLinks.telURL(phone) {
                Button { openURL(url) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "phone")
                            .font(AppFont.caption)
                        Text(phone)
                            .font(AppFont.caption)
                    }
                    .foregroundColor(AppColor.accent)
                }
                .buttonStyle(.plain)
            }

            // 안내사 추천 이유 — 추천 스팟에만 있음
            if let reason, !reason.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "hand.thumbsup")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.accent)
                    Text(reason)
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.accentSubtle)
                .cornerRadius(AppRadius.md)
            }

            // 카카오맵 장소 페이지 — 사진·리뷰·영업시간을 앱이 받지 못해 여기로 연결합니다
            if let placeUrl, let url = URL(string: placeUrl), !placeUrl.isEmpty {
                Button { openURL(url) } label: {
                    HStack(spacing: 6) {
                        Text("카카오맵에서 사진·리뷰 보기")
                            .font(AppFont.labelMedium)
                        Image(systemName: "arrow.up.right")
                            .font(AppFont.caption2)
                    }
                    .foregroundColor(AppColor.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(AppColor.accent.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if hours != nil || distance != nil {
                HStack(spacing: AppSpacing.sm) {
                    if let hours {
                        infoChip(icon: "clock", text: hours, color: AppColor.accent)
                    }
                    if let distance {
                        infoChip(icon: "location.circle", text: distance, color: AppColor.success)
                    }
                }
            }

            if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(AppFont.caption2Medium)
                            .foregroundColor(AppColor.accent)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(AppColor.accentSoft)
                            .cornerRadius(13)
                    }
                }
            }
            }
        }
    }

    private func infoChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(AppFont.caption2)
                .foregroundColor(color)
            Text(text)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textDark)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(color.opacity(0.08))
        .cornerRadius(AppRadius.sm)
    }

    // MARK: - 설명

    @ViewBuilder
    private var descriptionSection: some View {
        if let description, !description.isEmpty {
        VStack(alignment: .leading, spacing: 10) {
            Text("소개")
                .font(AppFont.bodyBold)
                .foregroundColor(AppColor.textPrimary)
            Text(description)
                .font(AppFont.label)
                .foregroundColor(AppColor.textDark)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 미니맵

    @ViewBuilder
    private var mapPreviewSection: some View {
        if let coordinate {
        VStack(alignment: .leading, spacing: 10) {
            Text("위치")
                .font(AppFont.bodyBold)
                .foregroundColor(AppColor.textPrimary)

            // 미리보기 전용 — 지도를 새로 띄우지 않고 정적 이미지로 그립니다
            // (카카오 지도를 겹쳐 띄우면 가끔 타일이 안 그려짐)
            StaticMapPreview(coordinate: coordinate)
                .frame(height: 150)
                .cornerRadius(AppRadius.lg)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 하단 버튼

    private var bottomButton: some View {
        Button { showRouteOptions = true } label: {
            Text("길찾기")
                .font(AppFont.bodyMBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(coordinate == nil ? AppColor.borderMuted : AppColor.accent)
                .cornerRadius(AppRadius.lg)
        }
        .buttonStyle(.plain)
        .disabled(coordinate == nil)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.white)
    }

    // MARK: - 길찾기

    /// 선택한 앱으로 길찾기를 엽니다.
    ///
    /// 애플 지도는 기기에 항상 있으므로 URL 스킴 대신 MKMapItem으로 바로 띄웁니다.
    /// 서드파티는 설치돼 있으면 앱으로, 없으면 웹 지도로 넘깁니다.
    private func openRoute(_ app: MapApp) {
        guard let coordinate else { return }
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if app == .apple {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            item.name = name
            item.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
            return
        }

        let appURL: URL?
        let webURL: URL?
        switch app {
        case .apple:
            return  // 위에서 처리
        case .kakao:
            appURL = URL(string: "kakaomap://route?ep=\(lat),\(lng)&by=CAR")
            webURL = URL(string: "https://map.kakao.com/link/to/\(encodedName),\(lat),\(lng)")
        case .google:
            appURL = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=driving")
            webURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lng)")
        }

        if let appURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL {
            UIApplication.shared.open(webURL)
        } else {
            toast = "길찾기를 열 수 없어요"
        }
    }

    private enum MapApp { case apple, kakao, google }

    // MARK: - 토스트

}

