import Foundation

// MARK: - Trip → TourSpotItem 변환
/// 내 일정 카드를 SpotDetailView로 표시하기 위한 변환
///
/// Trip의 정보를 TourSpotItem으로 매핑하여
/// 검색 탭과 동일한 상세보기 UI를 재활용한다.
///
/// 사용 예시:
/// ```swift
/// let spot = trip.toSpotItem()
/// SpotDetailView(spot: spot)
/// ```

extension Trip {

    /// Trip → TourSpotItem 변환
    ///
    /// - contentid: Trip.id 문자열
    /// - title: Trip.title
    /// - addr1: Trip.location
    /// - firstimage: Trip.thumbnailName (URL이면 그대로, 로컬이면 nil)
    /// - contenttypeid: "25" (여행코스)
    func toSpotItem() -> TourSpotItem {
        TourSpotItem(
            contentid: id.uuidString,
            title: title,
            addr1: location.isEmpty ? nil : location,
            addr2: nil,
            mapx: nil,
            mapy: nil,
            firstimage: thumbnailName.hasPrefix("http") ? thumbnailName : nil,
            firstimage2: nil,
            tel: nil,
            contenttypeid: "25"  // 여행코스
        )
    }
}
