import UIKit

public enum NBATeam: String, CaseIterable {
    
    case ATL, BKN, BOS, CHA, CHI, CLE, DAL, DEN, DET, GSW, HOU, IND, LAC, LAL, MEM, MIA, MIL, MIN, NOP, NYK, OKC, ORL, PHI, PHX, POR, SAC, SAS, TOR, UTA, WAS
    
    public var name: String {
        switch self {
        case .ATL:
            return String(localized: "Hawks")
        case .BKN:
            return String(localized: "Nets")
        case .BOS:
            return String(localized: "Celtics")
        case .CHA:
            return String(localized: "Hornets")
        case .CHI:
            return String(localized: "Bulls")
        case .CLE:
            return String(localized: "Cavaliers")
        case .DAL:
            return String(localized: "Mavericks")
        case .DEN:
            return String(localized: "Nuggets")
        case .DET:
            return String(localized: "Pistons")
        case .GSW:
            return String(localized: "Warriors")
        case .HOU:
            return String(localized: "Rockets")
        case .IND:
            return String(localized: "Pacers")
        case .LAC:
            return String(localized: "Clippers")
        case .LAL:
            return String(localized: "Lakers")
        case .MEM:
            return String(localized: "Grizzlies")
        case .MIA:
            return String(localized: "Heat")
        case .MIL:
            return String(localized: "Bucks")
        case .MIN:
            return String(localized: "Timberwolves")
        case .NOP:
            return String(localized: "Pelicans")
        case .NYK:
            return String(localized: "Knicks")
        case .OKC:
            return String(localized: "Thunder")
        case .ORL:
            return String(localized: "Magic")
        case .PHI:
            return String(localized: "76ers")
        case .PHX:
            return String(localized: "Suns")
        case .POR:
            return String(localized: "Trail Blazers")
        case .SAC:
            return String(localized: "Kings")
        case .SAS:
            return String(localized: "Spurs")
        case .TOR:
            return String(localized: "Raptors")
        case .UTA:
            return String(localized: "Jazz")
        case .WAS:
            return String(localized: "Wizards")
        }
    }
    
    public var logo: UIImage? {
        
        let bundleIdentifier: String = "com.jack51606.NBATeams"
        let bundle = Bundle(identifier: bundleIdentifier)
        let image = UIImage(named: rawValue, in: bundle, with: nil)
        
        switch self {
        case .UTA:
            guard let image else { return nil }
            if image.imageAsset?.image(with: UITraitCollection(userInterfaceStyle: .dark)) == nil {
                image.imageAsset?.register(image.withTintColor(.white), with: UITraitCollection(userInterfaceStyle: .dark))
            }
            return image.withRenderingMode(.alwaysTemplate)
        default:
            return image
        }
    }
}
