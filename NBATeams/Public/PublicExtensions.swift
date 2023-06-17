import UIKit
import RegexBuilder

private let finishedNBAGameTitleRegex: Regex = {
    
    return Regex {
        
        let teams = NBATeam.allCases.map { $0.name }
        
        Anchor.startOfSubject
        
        Capture {
            teams.dropFirst().reduce(AlternationBuilder.buildPartialBlock(first: teams[0])) {
                AlternationBuilder.buildPartialBlock(accumulated: $0, next: $1)
            }
        }
        " "
        Capture {
            Repeat(1...3) {
                One(.digit)
            }
        }
        ", "
        Capture {
            teams.dropFirst().reduce(AlternationBuilder.buildPartialBlock(first: teams[0])) {
                AlternationBuilder.buildPartialBlock(accumulated: $0, next: $1)
            }
        }
        " "
        Capture {
            Repeat(1...3) {
                One(.digit)
            }
        }
        
        Anchor.endOfSubject
    }
}()

private let scheduledNBAGameTitleRegex: Regex = {
    
    return Regex {
        
        let teams = NBATeam.allCases.map { $0.name }
        
        Anchor.startOfSubject
        
        Capture {
            teams.dropFirst().reduce(AlternationBuilder.buildPartialBlock(first: teams[0])) {
                AlternationBuilder.buildPartialBlock(accumulated: $0, next: $1)
            }
        }
        " "
        Capture {
            ChoiceOf {
                "Vs."
                "@"
            }
        }
        " "
        Capture {
            teams.dropFirst().reduce(AlternationBuilder.buildPartialBlock(first: teams[0])) {
                AlternationBuilder.buildPartialBlock(accumulated: $0, next: $1)
            }
        }
        
        Anchor.endOfSubject
    }
}()

extension String {
    
    public func NBAGameTitleAttributedText(font: UIFont) -> NSAttributedString? {
        guard self == firstMatch(of: scheduledNBAGameTitleRegex)?.output.0.base || self == firstMatch(of: finishedNBAGameTitleRegex)?.output.0.base else { return nil }
        
        enum State {
            case scheduled, finished
        }
        let state: State = self == firstMatch(of: scheduledNBAGameTitleRegex)?.output.0.base ? .scheduled : .finished
        
        var awayTeam: NBATeam?
        var homeTeam: NBATeam?
        
        var score1: Int?
        var score2: Int?
        
        switch state {
            
        case .scheduled:
            guard let output = firstMatch(of: scheduledNBAGameTitleRegex)?.output else { return nil }
            
            if output.2 == "@" {
                NBATeam.allCases.forEach {
                    if $0.name == output.1 {
                        awayTeam = $0
                    }
                    if $0.name == output.3 {
                        homeTeam = $0
                    }
                }
            } else {
                NBATeam.allCases.forEach {
                    if $0.name == output.1 {
                        homeTeam = $0
                    }
                    if $0.name == output.3 {
                        awayTeam = $0
                    }
                }
            }
            
        case .finished:
            guard let output = firstMatch(of: finishedNBAGameTitleRegex)?.output else { return nil }
            
            NBATeam.allCases.forEach {
                if $0.name == output.1 {
                    awayTeam = $0
                }
                if $0.name == output.3 {
                    homeTeam = $0
                }
            }
            
            score1 = Int(output.2)
            score2 = Int(output.4)
        }
        
        guard let awayTeam, let homeTeam, awayTeam != homeTeam else { return nil }
        
        guard let image1 = awayTeam.logo?.withConfiguration(UIImage.SymbolConfiguration(font: font, scale: .small)) else { return nil }
        guard let image2 = homeTeam.logo?.withConfiguration(UIImage.SymbolConfiguration(font: font, scale: .small)) else { return nil }
        
        let text = NSMutableAttributedString()
        
        let awayTeamLogo = NSAttributedString(attachment: NSTextAttachment(image: image1))
        let homeTeamLogo = NSAttributedString(attachment: NSTextAttachment(image: image2))
        
        let awayTeamName = NSAttributedString(string: awayTeam.name, attributes: [.font: font])
        let homeTeamName = NSAttributedString(string: homeTeam.name, attributes: [.font: font])
        
        let space = NSAttributedString(string: " ", attributes: [.font: font])
        let doubleSpace = NSAttributedString(string: "  ", attributes: [.font: font])
        let at = NSAttributedString(string: "@", attributes: [.font: font])
        
        switch state {
        case .scheduled:
            text.append(awayTeamLogo)
            text.append(doubleSpace)
            text.append(awayTeamName)
            text.append(space)
            text.append(at)
            text.append(space)
            text.append(homeTeamName)
            text.append(doubleSpace)
            text.append(homeTeamLogo)
        case .finished:
            guard let score1, let score2 else { return nil }
            let awayTeamFinalScore = NSAttributedString(string: String(score1), attributes: [.font: font, .foregroundColor: score1 > score2 ? UIColor.label : UIColor.secondaryLabel])
            let homeTeamFinalScore = NSAttributedString(string: String(score2), attributes: [.font: font, .foregroundColor: score1 > score2 ? UIColor.secondaryLabel : UIColor.label])
            
            let bundleIdentifier: String = "com.jack51606.NBATeams"
            let bundle = Bundle(identifier: bundleIdentifier)
            let indicatorImage = UIImage(named: score1 > score2 ? "winnerIndicator.left" : "winnerIndicator.right", in: bundle, with: UIImage.SymbolConfiguration(font: font, scale: .medium))
            var winnerIndicator: NSAttributedString {
                if let indicatorImage {
                    return NSAttributedString(attachment: NSTextAttachment(image: indicatorImage))
                } else {
                    return NSAttributedString(string: "")
                }
            }
            
            text.append(awayTeamLogo)
            text.append(doubleSpace)
            text.append(awayTeamFinalScore)
            text.append(doubleSpace)
            text.append(winnerIndicator)
            text.append(doubleSpace)
            text.append(homeTeamFinalScore)
            text.append(doubleSpace)
            text.append(homeTeamLogo)
        }
        
        return text
    }
}
