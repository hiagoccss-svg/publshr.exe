export interface MediaValueInput {
  authorityScore: number
  estimatedTraffic: number
  articleLength: number
  placementFactor?: number
  regionMultiplier?: number
}

/**
 * Enterprise-style media value estimation based on publication authority
 * and traffic — not random numbers. Formulas can be customised by admins later.
 */
export function calculateMediaValue(input: MediaValueInput): {
  mediaValue: number
  prValue: number
  reach: number
  advertisingEquivalent: number
} {
  const placement = input.placementFactor ?? 1
  const regionMult = input.regionMultiplier ?? 1
  const lengthFactor = Math.min(1.5, 0.5 + input.articleLength / 2000)

  const authorityWeight = input.authorityScore / 100
  const trafficBase = Math.sqrt(input.estimatedTraffic) * 0.15

  const mediaValue = Math.round(
    trafficBase * authorityWeight * lengthFactor * placement * regionMult * 100
  )

  const prValue = Math.round(mediaValue * 1.35)
  const reach = Math.round(
    input.estimatedTraffic * 0.02 * authorityWeight * lengthFactor * placement
  )
  const advertisingEquivalent = Math.round(mediaValue * 0.85)

  return { mediaValue, prValue, reach, advertisingEquivalent }
}
