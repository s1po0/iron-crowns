# Iron Crowns

An original Android action-strategy **playable 2D prototype**: lead a company, trade between settlements, fight real-time battles, and capture three keeps.

> This is a small native Java/Canvas vertical slice, not the completed 3D Unity/Unreal game described in the design plan.

## Download and play

Get the APK from [GitHub Releases](https://github.com/s1po0/iron-crowns/releases). Requires Android 8.0 or later. The prototype is offline, with no ads, purchases, or network permissions. Prerelease APKs use debug signing and are not Play Store production packages.

See [installation, controls, build instructions, and limitations](docs/PROTOTYPE.md).

## Source and build

- `app/`: native Android game and campaign rules.
- `tests/`: platform-independent campaign tests and invariant checks.
- `.github/workflows/android.yml`: reproducible Android APK build and lint workflow.
- `scripts/test.sh`: compile/run rules tests with JDK 17.

```bash
bash scripts/test.sh
gradle --no-daemon :app:assembleDebug :app:lintDebug
```

Requires JDK 17, Gradle 8.9, and Android SDK 35. See the prototype guide for details.

## Long-term design

[Master Game Design Specification & Technical Architecture Plan](docs/MASTER_GDD_AND_TECHNICAL_PLAN.md) describes the larger 3D game, proposed Unity architecture, performance targets, and Notion/Linear/GitHub workflow. Those roadmap features are not all implemented in this prototype.
