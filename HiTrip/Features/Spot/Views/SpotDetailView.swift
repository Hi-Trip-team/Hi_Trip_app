import SwiftUI

// MARK: - SpotDetailView
/// 관광지 상세 화면 (Sheet)
///
/// TourAPI에서 가져온 관광지 정보를 보여줌:
/// - 대표 이미지
/// - 이름, 주소, 유형, 전화번호
/// - "지도 보기" 버튼 → SpotMapView (전체화면 KakaoMap)
/// - 전화 걸기 버튼 (tel://)

struct SpotDetailView: View {

    let spot: TourSpotItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    /// SpotMapView 표시 여부
    @State private var showMap = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - 대표 이미지
                    spotHeaderImage

                    VStack(alignment: .leading, spacing: 16) {
                        // MARK: - 제목 + 유형
                        titleSection

                        Divider()

                        // MARK: - 지도 보기 버튼
                        if spot.latitude != nil && spot.longitude != nil {
                            mapButton
                        }

                        // MARK: - 주소
                        if !spot.fullAddress.isEmpty {
                            infoRow(
                                icon: "mappin.and.ellipse",
                                title: "주소",
                                content: spot.fullAddress
                            )
                        }

                        // MARK: - 전화번호
                        if let tel = spot.tel, !tel.isEmpty {
                            Button {
                                let cleaned = tel.replacingOccurrences(of: " ", with: "")
                                    .replacingOccurrences(of: "-", with: "")
                                if let url = URL(string: "tel://\(cleaned)") {
                                    openURL(url)
                                }
                            } label: {
                                infoRow(
                                    icon: "phone.fill",
                                    title: "전화",
                                    content: tel,
                                    isLink: true
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()

                        // MARK: - 관광지 유형
                        infoRow(
                            icon: "tag.fill",
                            title: "유형",
                            content: spot.contentTypeName
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle(spot.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showMap) {
                SpotMapView(spot: spot)
            }
        }
    }

    // MARK: - 지도 보기 버튼

    /// KakaoMap 전체화면으로 이동하는 버튼
    /// Metal 기반 KakaoMap은 ScrollView 안에서 GPU 충돌이 발생하므로
    /// 별도의 전체화면(fullScreenCover)으로 표시
    private var mapButton: some View {
        Button {
            showMap = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)

                Text("지도에서 위치 보기")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(HiTripColor.primary800)
            .cornerRadius(12)
        }
    }

    // MARK: - 헤더 이미지

    private var spotHeaderImage: some View {
        Group {
            if let imageURL = spot.firstimage, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        headerPlaceholder
                    case .empty:
                        ZStack {
                            headerPlaceholder
                            ProgressView()
                        }
                    @unknown default:
                        headerPlaceholder
                    }
                }
            } else {
                headerPlaceholder
            }
        }
        .frame(height: 220)
        .clipped()
    }

    private var headerPlaceholder: some View {
        Rectangle()
            .fill(HiTripColor.gray100)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(HiTripColor.gray300)
                    Text("이미지 없음")
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray400)
                }
            )
    }

    // MARK: - 제목 섹션

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(spot.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textGrayA)

            Text(spot.contentTypeName)
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.primary800)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(HiTripColor.secondary100)
                .cornerRadius(6)
        }
    }

    // MARK: - 정보 행

    private func infoRow(
        icon: String,
        title: String,
        content: String,
        isLink: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(HiTripColor.primary800)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray400)

                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(isLink ? .blue : HiTripColor.textGrayA)
            }
        }
    }
}
