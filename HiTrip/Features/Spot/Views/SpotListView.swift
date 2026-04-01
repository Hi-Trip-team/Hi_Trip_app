import SwiftUI

// MARK: - SpotListView
/// 관광지 검색 목록 화면
///
/// 구성:
/// - 상단: 검색 모드 선택 (키워드/주변) + 검색바
/// - 중간: 검색 결과 리스트 (이미지 + 이름 + 주소 + 유형 뱃지)
/// - 탭하면 SpotDetailView로 이동
///
/// 새로운 패턴:
/// - Picker(.segmented)로 검색 모드 전환
/// - AsyncImage로 원격 이미지 로드
/// - onAppear last item 으로 페이지네이션

struct SpotListView: View {

    @ObservedObject var viewModel: SpotViewModel
    @State private var selectedSpot: TourSpotItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 검색 모드 + 검색바
                searchHeader

                // MARK: - 결과 목록
                if viewModel.isLoading && viewModel.spots.isEmpty {
                    loadingView
                } else if viewModel.spots.isEmpty {
                    emptyStateView
                } else {
                    spotList
                }
            }
            .navigationTitle("스팟 추천")
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(spot: spot)
            }
        }
    }

    // MARK: - 검색 헤더

    private var searchHeader: some View {
        VStack(spacing: 12) {
            // 검색 모드 선택
            Picker("검색 모드", selection: $viewModel.searchMode) {
                ForEach(SpotViewModel.SearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            // 키워드 검색바
            if viewModel.searchMode == .keyword {
                HStack(spacing: 8) {
                    TextField("관광지 검색 (예: 제주, 경복궁)", text: $viewModel.searchText)
                        .font(.system(size: 15))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(HiTripColor.gray100)
                        .cornerRadius(10)

                    Button {
                        viewModel.searchByKeyword()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(HiTripColor.primary800)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.searchText.trimmed.isEmpty)
                }
                .padding(.horizontal, 16)
            } else {
                // 주변 검색 버튼
                Button {
                    viewModel.searchNearby()
                } label: {
                    Label("현재 위치에서 검색", systemImage: "location.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HiTripColor.primary800)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
            }

            // 에러 메시지
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.error)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 결과 리스트

    private var spotList: some View {
        List {
            ForEach(viewModel.spots) { spot in
                Button {
                    selectedSpot = spot
                } label: {
                    spotRow(spot)
                }
                .buttonStyle(.plain)
                .onAppear {
                    // 마지막 항목이 보이면 다음 페이지 로드 (페이지네이션)
                    if spot.id == viewModel.spots.last?.id && viewModel.hasMore {
                        viewModel.loadMoreKeyword()
                    }
                }
            }

            // 로딩 인디케이터 (더보기 중)
            if viewModel.isLoading && !viewModel.spots.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - 관광지 행

    private func spotRow(_ spot: TourSpotItem) -> some View {
        HStack(spacing: 12) {
            // 대표 이미지
            spotImage(spot.firstimage)

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                Text(spot.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HiTripColor.textGrayA)
                    .lineLimit(1)

                // 주소
                if !spot.fullAddress.isEmpty {
                    Text(spot.fullAddress)
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray400)
                        .lineLimit(1)
                }

                // 유형 뱃지
                Text(spot.contentTypeName)
                    .font(.system(size: 11))
                    .foregroundColor(HiTripColor.primary800)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(HiTripColor.secondary100)
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - 이미지 로드

    /// AsyncImage로 원격 이미지 로드
    /// 이미지가 없으면 기본 아이콘 표시
    private func spotImage(_ urlString: String?) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(width: 72, height: 72)
        .cornerRadius(8)
        .clipped()
    }

    /// 이미지 없을 때 기본 표시
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(HiTripColor.gray100)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(HiTripColor.gray300)
            )
    }

    // MARK: - 빈 상태 / 로딩

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(HiTripColor.gray300)
            Text("관광지를 검색해보세요")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(HiTripColor.textGrayA)
            Text("키워드 또는 현재 위치로 검색할 수 있어요")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("검색 중...")
            Spacer()
        }
    }
}
