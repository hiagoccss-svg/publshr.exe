import Foundation

/// ClickUp Spaces Home — keep aligned with `shared/spaces/spaces-home.ts`.
enum SpacesHomeLogic {
    enum SectionId: String {
        case pinned, favorites, all
    }

    struct Section: Identifiable {
        let sectionId: SectionId
        let title: String
        let spaces: [SpaceRecord]
        var id: String { sectionId.rawValue }
    }

    struct Filters: Equatable {
        var query: String = ""
        var typeFilter: String = "all"
        var showArchived: Bool = false
    }

    static func normalizeSpaceType(_ type: String) -> String {
        SpaceTypeWire.fromDatabase(type)
    }

    static func spaceTypeLabel(_ type: String) -> String {
        let key = normalizeSpaceType(type)
        if let match = SpaceTypeOption.allCases.first(where: { $0.rawValue == key }) {
            return match.label
        }
        return key.capitalized
    }

    static func filter(_ spaces: [SpaceRecord], filters: Filters) -> [SpaceRecord] {
        let q = filters.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return spaces.filter { space in
            if !filters.showArchived && space.isArchived { return false }
            if filters.typeFilter != "all", normalizeSpaceType(space.type) != filters.typeFilter {
                return false
            }
            if !q.isEmpty {
                let hay = [
                    space.name.lowercased(),
                    space.description.lowercased(),
                    spaceTypeLabel(space.type).lowercased()
                ]
                if !hay.contains(where: { $0.contains(q) }) { return false }
            }
            return true
        }
    }

    static func sections(from spaces: [SpaceRecord]) -> [Section] {
        let pinned = spaces.filter(\.isPinned)
        let favourites = spaces.filter { $0.isFavourite && !$0.isPinned }
        let rest = spaces.filter { !$0.isPinned && !$0.isFavourite }
        var out: [Section] = []
        if !pinned.isEmpty {
            out.append(Section(sectionId: .pinned, title: "Pinned", spaces: pinned))
        }
        if !favourites.isEmpty {
            out.append(Section(sectionId: .favorites, title: "Favorites", spaces: favourites))
        }
        let pool = rest.isEmpty ? spaces : rest
        if !pool.isEmpty {
            let title = pinned.isEmpty && favourites.isEmpty ? "Spaces" : "All Spaces"
            out.append(Section(sectionId: .all, title: title, spaces: pool))
        }
        return out
    }

    static func buildSections(from spaces: [SpaceRecord], filters: Filters) -> [Section] {
        sections(from: filter(spaces, filters: filters))
    }
}
