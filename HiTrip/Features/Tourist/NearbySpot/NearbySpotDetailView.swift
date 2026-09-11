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

    var name: String
    var address: String?
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

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603),
        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
    )


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
                    descriptionSection
                        .padding(.horizontal, AppSpacing.lg)
                    Divider()
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    mapPreviewSection
                        .padding(.horizontal, AppSpacing.lg)
                    Spacer().frame(height: 32)
                }
            }

            bottomButton
        }
        .background(Color.white)
        .overlay(alignment: .bottom) { toastView }
        .animation(.easeInOut(duration: 0.2), value: toast)
        .navigationBarHidden(true)
        .confirmationDialog("길찾기", isPresented: $showRouteOptions, titleVisibility: .visible) {
            Button("카카오맵") { openRoute(.kakao) }
            Button("구글 지도") { openRoute(.google) }
            Button("취소", role: .cancel) { }
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        ZStack {
            Text(name)
                .font(AppFont.headlineBold)
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(AppFont.title3Medium)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .frame(height: 44)
        .padding(.top, AppSpacing.xs)
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
                    .frame(height: 200)
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
        if coordinate != nil {
        VStack(alignment: .leading, spacing: 10) {
            Text("위치")
                .font(AppFont.bodyBold)
                .foregroundColor(AppColor.textPrimary)

            Map(coordinateRegion: $region, annotationItems: [nearbyPin]) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    ZStack {
                        Circle()
                            .fill(AppColor.accent)
                            .frame(width: 28, height: 28)
                        Image(systemName: "mappin")
                            .font(AppFont.captionBold)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 150)
            .cornerRadius(AppRadius.lg)
            .disabled(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if let coordinate {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                )
            }
        }
        }
    }

    private var nearbyPin: NearbyPin {
        NearbyPin(coordinate: coordinate ?? region.center)
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

    /// 카카오맵 → 구글맵 순으로 설치된 앱을 띄우고, 없으면 웹 지도로 넘깁니다.
    private func openRoute(_ app: MapApp) {
        guard let coordinate else { return }
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let appURL: URL?
        let webURL: URL?
        switch app {
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

    private enum MapApp { case kakao, google }

    // MARK: - 토스트

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(AppFont.labelMedium)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(AppColor.textPrimary.opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 90)
                .transition(.opacity)
                .task(id: toast) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.toast = nil
                }
        }
    }
}

private struct NearbyPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
