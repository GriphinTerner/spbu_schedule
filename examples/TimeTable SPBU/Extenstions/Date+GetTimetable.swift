import Foundation

enum TimetableError: LocalizedError {
    case noInternet
    case decodingFailed
    case badResponse(Int)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "Нет подключения к интернету. Проверьте сеть."
        case .decodingFailed:
            return "Ошибка обработки данных с сервера."
        case .badResponse(let code):
            return "Сервер вернул ошибку (\(code))."
        case .unknown:
            return "Произошла неизвестная ошибка."
        }
    }
}


extension Date {
    static func getTimetableRange(
        for groupId: Int,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [Date: [Event]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let fromStr = formatter.string(from: startDate)
        let toStr = formatter.string(from: endDate)

        let urlString = "https://timetable.spbu.ru/api/v1/groups/\(groupId)/events/\(fromStr)/\(toStr)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw TimetableError.badResponse(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            
            do {
                let response = try decoder.decode(TimetableResponse.self, from: data)
                var dict: [Date: [Event]] = [:]
                
                let dayFormatter = DateFormatter()
                dayFormatter.locale = Locale(identifier: "en_US_POSIX")
                dayFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                
                for day in response.Days {
                    if let date = dayFormatter.date(from: day.Day) {
                        dict[date] = day.DayStudyEvents.unique()
                    }
                }
                return dict
            } catch {
                throw TimetableError.decodingFailed
            }
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw TimetableError.noInternet
        } catch {
            throw TimetableError.unknown
        }
    }
}
