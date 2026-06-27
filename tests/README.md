# PvPTooltip Test Suite

This directory contains a comprehensive test suite for the PvPTooltip addon, covering unit tests, integration tests, and performance benchmarks.

## Test Structure

### Test Files

- **TestSuite.lua** - Main test coordinator and runner
- **TestConfig.lua** - Configuration settings for all tests
- **RunTests.lua** - Convenient test runner with global functions
- **DatabaseTests.lua** - Unit tests for database loading and management
- **PlayerLookupTests.lua** - Unit tests for player lookup functionality
- **TooltipRenderingTests.lua** - Integration tests for tooltip rendering
- **PerformanceBenchmarks.lua** - Performance benchmarks and memory usage tests
- **IntegrationTests.lua** - End-to-end integration tests
- **ErrorHandlingTests.lua** - Error handling tests (existing)
- **PerformanceTests.lua** - Performance tests (existing)

### Test Categories

1. **Unit Tests** - Test individual components in isolation
   - Database loading and validation
   - Player lookup functionality
   - Data validation and sanitization
   - Error handling and graceful degradation

2. **Integration Tests** - Test component interactions and workflows
   - Complete addon workflow (unit hover → lookup → tooltip display)
   - Cross-component communication
   - Event handling integration
   - Configuration integration

3. **Performance Tests** - Benchmark performance and memory usage
   - Database lookup performance
   - Tooltip rendering performance
   - Memory usage and leak detection
   - Cache performance
   - Stress testing under load

## Running Tests

### Quick Start

Load the addon and run in WoW console:

```lua
-- Run all tests
/run RunPvPTooltipTests()

-- Run quick smoke tests
/run RunPvPTooltipQuickTests()

-- Run specific categories
/run RunPvPTooltipUnitTests()
/run RunPvPTooltipIntegrationTests()
/run RunPvPTooltipPerformanceTests()
```

### Individual Module Tests

```lua
-- Test specific modules
/run RunDatabaseTests()
/run RunPlayerLookupTests()
/run RunTooltipRenderingTests()
/run RunPerformanceBenchmarks()
/run RunIntegrationTests()
/run RunErrorHandlingTests()
```

### Advanced Usage

```lua
-- Get detailed results
local results = PvPTooltipTestRunner:GetLastResults()

-- Generate JSON report
local jsonReport = PvPTooltipTestRunner:GenerateReport("json")

-- Run specific test module
local moduleResults = PvPTooltipTestRunner:RunModule("DatabaseTests")

-- Configure test settings
PvPTooltip.TestSuite:SetTestConfig({
    verboseOutput = true,
    stopOnFirstFailure = true
})
```

## Test Coverage

### Database Tests
- ✅ Database initialization and loading
- ✅ Player data retrieval and validation
- ✅ Cache management and performance
- ✅ Error handling with corrupted data
- ✅ Memory management and cleanup
- ✅ Realm name normalization
- ✅ Data structure validation

### Player Lookup Tests
- ✅ Unit information extraction
- ✅ Player data lookup workflows
- ✅ Cross-faction and cross-realm handling
- ✅ Cache functionality and performance
- ✅ Error handling and graceful degradation
- ✅ Validation functions
- ✅ Name and realm variations

### Tooltip Rendering Tests
- ✅ Tooltip enhancement workflows
- ✅ Section rendering (rating, experience, season)
- ✅ Color formatting and display
- ✅ Data validation and error handling
- ✅ Performance characteristics
- ✅ Component integration
- ✅ Layout and alignment

### Performance Benchmarks
- ✅ Database lookup performance
- ✅ Tooltip rendering performance
- ✅ Memory usage and leak detection
- ✅ Cache access performance
- ✅ Initialization performance
- ✅ Validation performance
- ✅ Stress testing under load

### Integration Tests
- ✅ Complete addon workflow
- ✅ Event handling integration
- ✅ Cross-component communication
- ✅ Error recovery and graceful degradation
- ✅ Configuration integration
- ✅ Performance under load
- ✅ Compatibility scenarios
- ✅ Data consistency across components

## Performance Thresholds

The test suite validates performance against these thresholds:

- **Database Lookup**: < 50ms per lookup
- **Tooltip Rendering**: < 10ms per render
- **Memory Usage**: < 1MB total addon memory
- **Cache Access**: < 1ms per access
- **Initialization**: < 5 seconds total
- **Validation**: < 0.1ms per validation

## Test Configuration

Tests can be configured via `TestConfig.lua`:

```lua
local config = {
    execution = {
        enableUnitTests = true,
        enableIntegrationTests = true,
        enablePerformanceTests = true,
        verboseOutput = false,
        stopOnFirstFailure = false,
        testTimeout = 30
    },
    performance = {
        thresholds = {
            databaseLookup = 50,
            tooltipRender = 10,
            memoryUsage = 1024
        }
    }
}
```

## Test Utilities

The test suite provides utilities for creating mock data:

```lua
-- Create mock tooltip
local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()

-- Create mock player data
local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("PlayerName", "realm", "eu")

-- Assertion functions
PvPTooltip.TestUtils.AssertEquals(expected, actual, message)
PvPTooltip.TestUtils.AssertNotNil(value, message)
PvPTooltip.TestUtils.AssertTrue(condition, message)

-- Performance measurement
local success, result, time = PvPTooltip.TestUtils.MeasureTime(function)
local success, result, memory = PvPTooltip.TestUtils.MeasureMemory(function)
```

## Error Handling

The test suite includes comprehensive error handling tests:

- Corrupted database files
- Invalid player data structures
- Missing dependencies
- Tooltip rendering errors
- Memory leaks and excessive usage
- Network timeouts and failures
- Configuration errors

## Continuous Integration

Tests are designed to be run automatically and provide machine-readable output:

```lua
-- Get test results in JSON format
local results = PvPTooltipTestRunner:GenerateReport("json")

-- Check if all tests passed
local allPassed = results.summary.failedTests == 0
```

## Troubleshooting

### Common Issues

1. **Tests not running**: Ensure the addon is fully loaded and initialized
2. **Performance test failures**: Check system load and WoW performance settings
3. **Memory test failures**: Run tests with minimal other addons loaded
4. **Integration test failures**: Verify all addon components are properly initialized

### Debug Mode

Enable debug output for detailed test execution information:

```lua
PvPTooltip.TestSuite:SetTestConfig({
    verboseOutput = true,
    debug = {
        enableDebugOutput = true,
        logTestExecution = true,
        captureErrorDetails = true
    }
})
```

## Contributing

When adding new tests:

1. Follow the existing test structure and naming conventions
2. Include both positive and negative test cases
3. Add performance benchmarks for new functionality
4. Update this README with new test coverage
5. Ensure tests are deterministic and don't depend on external state

## Requirements Validation

This test suite validates all requirements from the PvPTooltip specification:

- **Requirement 1**: Player tooltip display across all game contexts ✅
- **Requirement 2**: Current PvP ratings with color coding ✅
- **Requirement 3**: Personal best ratings (experience) ✅
- **Requirement 4**: Current season statistics ✅
- **Requirement 5**: EU/US region database support ✅
- **Requirement 6**: Clear visual formatting ✅
- **Requirement 7**: Comprehensive documentation ✅
- **Requirement 8**: Automated release processes ✅

The test suite ensures all functionality works correctly and performs within acceptable limits.