import Foundation

// MARK: - Корневой объект расписания
struct TimetableResponse: Decodable {
    let StudentGroupId: Int
    let StudentGroupDisplayName: String
    let TimeTableDisplayName: String
    let PreviousWeekMonday: String?   // всегда null
    let NextWeekMonday: String?       // всегда null
    let IsPreviousWeekReferenceAvailable: Bool
    let IsNextWeekReferenceAvailable: Bool
    let IsCurrentWeekReferenceAvailable: Bool
    let WeekDisplayText: String?      // всегда null
    let WeekMonday: String?           // всегда null
    let Days: [DayItem]
}



// MARK: - День
struct DayItem: Decodable {
    let Day: String
    let DayString: String
    let DayStudyEvents: [Event]
}

// MARK: - Событие
struct Event: Codable, Identifiable, Hashable {
    let uuid: UUID = UUID() 

    var id: String { uuid.uuidString }

    let StudyEventsTimeTableKindCode: Int
    let Start: String
    let End: String
    let Subject: String
    let TimeIntervalString: String
    let DateWithTimeIntervalString: String
    let DisplayDateAndTimeIntervalString: String
    let LocationsDisplayText: String?
    let EducatorsDisplayText: String?
    let HasEducators: Bool
    let IsCancelled: Bool
    let ContingentUnitName: String?
    let DivisionAndCourse: String?
    let IsAssigned: Bool
    let TimeWasChanged: Bool
    let LocationsWereChanged: Bool
    let EducatorsWereReassigned: Bool
    let ElectiveDisciplinesCount: Int
    let IsElective: Bool
    let HasTheSameTimeAsPreviousItem: Bool
    let ContingentUnitsDisplayTest: String?
    let IsStudy: Bool
    let AllDay: Bool
    let WithinTheSameDay: Bool
    let EventLocations: [EventLocation]
    let EducatorIds: [EducatorId]

    enum CodingKeys: CodingKey {
        case StudyEventsTimeTableKindCode, Start, End, Subject, TimeIntervalString,
             DateWithTimeIntervalString, DisplayDateAndTimeIntervalString, LocationsDisplayText,
             EducatorsDisplayText, HasEducators, IsCancelled, ContingentUnitName,
             DivisionAndCourse, IsAssigned, TimeWasChanged, LocationsWereChanged,
             EducatorsWereReassigned, ElectiveDisciplinesCount, IsElective,
             HasTheSameTimeAsPreviousItem, ContingentUnitsDisplayTest, IsStudy,
             AllDay, WithinTheSameDay, EventLocations, EducatorIds
    }
}


// MARK: - Локация
struct EventLocation: Codable, Hashable {
    let IsEmpty: Bool
    let DisplayName: String
    let HasGeographicCoordinates: Bool
    let Latitude: Double
    let Longitude: Double
    let LatitudeValue: String?
    let LongitudeValue: String?
    let EducatorsDisplayText: String?
    let HasEducators: Bool
    let EducatorIds: [EducatorId]
}

// MARK: - Преподаватель
struct EducatorId: Codable, Hashable {
    let Item1: Int
    let Item2: String
}

// MARK: - Фильтрация дублей
extension Array where Element == Event {
    func unique() -> [Event] {
        var seen = Set<String>()
        return self.filter { event in
            let key = event.Start + event.End + event.Subject + (event.EducatorsDisplayText ?? "")
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
}
