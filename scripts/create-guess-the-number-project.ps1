# --- Configuration ---
$sourceDir = "src"
$testDir = "tests"
$gameName = "GuessTheNumber"
$coreProjectName = "$gameName.Core"
$consoleProjectName = "$gameName.ConsoleGui"
$testProjectName = "$gameName.Core.Tests"
$solutionName = "$gameName.sln"
$wikiDir = "wiki" # Local directory name for the wiki submodule

# --- Directory Setup ---
Write-Host "Ensuring base directories exist..."
if (-Not (Test-Path -Path $sourceDir -PathType Container)) { New-Item -ItemType Directory -Path $sourceDir }
if (-Not (Test-Path -Path $testDir -PathType Container)) { New-Item -ItemType Directory -Path $testDir }

# --- Project Creation ---
$gameSourceBaseDir = Join-Path $sourceDir $gameName # e.g., src/GuessTheNumber
$coreProjectDir = Join-Path $gameSourceBaseDir $coreProjectName # e.g., src/GuessTheNumber/GuessTheNumber.Core
$consoleProjectDir = Join-Path $gameSourceBaseDir $consoleProjectName # e.g., src/GuessTheNumber/GuessTheNumber.ConsoleGui
$testProjectDir = Join-Path $testDir $testProjectName # e.g., tests/GuessTheNumber.Core.Tests
$solutionDir = $gameSourceBaseDir # Place solution in the game's source folder, e.g., src/GuessTheNumber

Write-Host "Creating project directories..."
New-Item -ItemType Directory -Path $gameSourceBaseDir -Force
New-Item -ItemType Directory -Path $coreProjectDir -Force
New-Item -ItemType Directory -Path $consoleProjectDir -Force
New-Item -ItemType Directory -Path $testProjectDir -Force

Write-Host "Creating .NET projects..."
dotnet new classlib -n $coreProjectName -o $coreProjectDir --force
dotnet new console -n $consoleProjectName -o $consoleProjectDir --force
dotnet new xunit -n $testProjectName -o $testProjectDir --force

# --- Solution Setup ---
$solutionPath = Join-Path $solutionDir $solutionName # e.g., src/GuessTheNumber/GuessTheNumber.sln
Write-Host "Creating solution file: $solutionPath"
dotnet new sln -n $gameName -o $solutionDir --force

# --- Add Projects to Solution (Corrected) ---
# Define full paths to project files
$coreProjectPath = Join-Path $coreProjectDir "$coreProjectName.csproj"
$consoleProjectPath = Join-Path $consoleProjectDir "$consoleProjectName.csproj"
$testProjectPath = Join-Path $testProjectDir "$testProjectName.csproj"

Write-Host "Adding projects to solution '$solutionPath'..."
# Use the explicit solution path and quoted project paths
dotnet sln "$solutionPath" add "$coreProjectPath"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to add $coreProjectName to solution."; exit 1 }

dotnet sln "$solutionPath" add "$consoleProjectPath"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to add $consoleProjectName to solution."; exit 1 }

dotnet sln "$solutionPath" add "$testProjectPath"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to add $testProjectName to solution."; exit 1 }

# --- Project References ---
Write-Host "Adding project references..."
# Reference Core from ConsoleGui (Use full paths)
dotnet add "$consoleProjectPath" reference "$coreProjectPath"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to add reference from $consoleProjectName to $coreProjectName."; exit 1 }

# Reference Core from Tests (Use full paths)
dotnet add "$testProjectPath" reference "$coreProjectPath"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to add reference from $testProjectName to $coreProjectName."; exit 1 }


# --- Wiki GDD Stub Creation ---
Write-Host "Attempting to create Wiki GDD stub..."
if (Test-Path -Path $wikiDir -PathType Container) {
    # Corrected Join-Path: Join two segments at a time
    $wikiGamesDir = Join-Path $wikiDir "Games"
    $wikiGameDir = Join-Path $wikiGamesDir $gameName # e.g., wiki/Games/GuessTheNumber
    $wikiGddFile = Join-Path $wikiGameDir "$gameName-GDD.md" # e.g., wiki/Games/GuessTheNumber/GuessTheNumber-GDD.md

    # Create game-specific directory in wiki
    # Ensure the base "Games" directory exists first
    if (-Not (Test-Path -Path $wikiGamesDir -PathType Container)) {
         New-Item -ItemType Directory -Path $wikiGamesDir -Force
         Write-Host "Created base wiki directory: $wikiGamesDir"
    }
    # Now create the specific game directory
    if (-Not (Test-Path -Path $wikiGameDir -PathType Container)) {
        New-Item -ItemType Directory -Path $wikiGameDir -Force
        Write-Host "Created wiki directory: $wikiGameDir"
    } else {
         Write-Host "Wiki game directory already exists: $wikiGameDir"
    }

    # Create placeholder GDD file if it doesn't exist
    if (-Not (Test-Path -Path $wikiGddFile -PathType Leaf)) {
        Write-Host "Creating placeholder GDD file: $wikiGddFile"
        # Basic GDD template
        $gddContent = @"
# Game Design Document: $gameName

## 1. Overview
*(Provide a brief, high-level description of the game. What is the core concept?)*

## 2. Core Gameplay
*(Describe the main loop, player actions, rules, and objectives.)*
- Goal: Guess the secret number.
- Input: Player enters a number.
- Feedback: "Too high", "Too low", "Correct!".
- Win Condition: Guessing the correct number.
- Lose Condition: (Optional: e.g., running out of attempts).

## 3. Features
*(List the key features.)*
- Random number generation within a configurable range (e.g., 1-100).
- User input handling for guesses.
- Feedback mechanism based on guess comparison.
- Tracking number of attempts.
- (Future) Difficulty levels (adjust range/attempts).
- (Future) Play again option.

## 4. Console UI (gui.cs)
*(Brief description of the intended console interface.)*
- Display prompts for input.
- Show feedback messages.
- Display number of attempts remaining/used.
- Clear win/lose message.

## 5. Technical Design
*(Brief notes on implementation.)*
- Core logic in `$coreProjectName`.
- Console interface in `$consoleProjectName` using `gui.cs`.
- Unit tests in `$testProjectName` for core logic.
- Secret number generation using `System.Random`.

## 6. Milestones
*(Optional: Break down development.)*
- M1: Core logic (number generation, guess checking, attempt tracking) + TDD tests.
- M2: Basic Console UI (input/output).
- M3: Integrate `gui.cs` for improved interface.
- M4: Add 'Play Again' functionality.
"@
        # Ensure the directory exists before writing the file
        if (Test-Path -Path $wikiGameDir -PathType Container) {
             Set-Content -Path $wikiGddFile -Value $gddContent
             Write-Host "Created placeholder GDD: $wikiGddFile"
        } else {
             Write-Error "Failed to create GDD file because directory '$wikiGameDir' could not be created or found."
        }
    } else {
        Write-Host "GDD file already exists: $wikiGddFile. No changes made."
    }
} else {
    Write-Warning "Wiki directory '$wikiDir' not found. Skipping GDD stub creation."
    Write-Warning "Ensure the wiki submodule is added and initialized ('git submodule update --init --recursive')."
}


Write-Host "-----------------------------------------------------"
Write-Host "Project structure for '$gameName' created successfully!" -ForegroundColor Green
Write-Host "Attempted to create GDD stub in '$wikiDir/Games/$gameName'."
Write-Host "Remember to use 'manage-wiki.ps1' or git commands in '$wikiDir' to commit/push wiki changes."
Write-Host "-----------------------------------------------------"
