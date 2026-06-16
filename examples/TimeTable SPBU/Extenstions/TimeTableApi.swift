//import Foundation
//
//final class TimetableAPI {
//    static let shared = TimetableAPI()
//    private init() {}
//
//    // MARK: - Получить факультеты
//    func fetchFaculties() async throws -> [Faculty] {
//        let url = URL(string: "https://timetable.spbu.ru/api/v1/study/divisions")!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return try JSONDecoder().decode([Faculty].self, from: data)
//    }
//
//    // MARK: - Получить направления для факультета
//    func fetchPrograms(for facultyId: String) async throws -> [StudyProgram] {
//        let url = URL(string: "https://timetable.spbu.ru/api/v1/study/divisions/\(facultyId)/programs/levels")!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return try JSONDecoder().decode([StudyProgram].self, from: data)
//    }
//
//    // MARK: - Получить группы для программы
//    func fetchGroups(for programId: Int) async throws -> [Group] {
//        let url = URL(string: "https://timetable.spbu.ru/api/v1/programs/\(programId)/groups")!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return try JSONDecoder().decode([Group].self, from: data)
//    }
//}
