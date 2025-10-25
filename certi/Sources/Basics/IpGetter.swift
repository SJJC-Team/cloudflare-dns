#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

func getPublicIPAddress() async throws -> String {
    let urls = [
        "https://api.ipify.org",
        "https://ifconfig.me/ip",
        "https://checkip.amazonaws.com"
    ]

    for urlString in urls {
        guard let url = URL(string: urlString) else { continue }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let ip = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !ip.isEmpty {
                return ip
            }
        } catch {
            continue
        }
    }

    throw NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch IP"])
}