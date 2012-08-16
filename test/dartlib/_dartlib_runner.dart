#library('dartlib_test_core');

#import('../../vendor/unittest/unittest.dart');
#import('../../lib/dartlib.dart');
#import('../../lib/test.dart');

#source('test_cloneable.dart');
#source('events/test_events.dart');

#source('collection/test_enumerable.dart');
#source('collection/test_number_enumerable.dart');
#source('collection/test_list_base.dart');
#source('collection/test_collection_util.dart');
#source('collection/test_array_2d.dart');

#source('test_util.dart');
#source('math/test_coordinate.dart');
#source('math/test_vector.dart');
#source('math/test_affine_transform.dart');
#source('math/test_rect.dart');
#source('graph/test_tarjan.dart');

#source('color/test_rgb_color.dart');
#source('color/test_hsl_color.dart');

#source('property/test_property_event_integration.dart');
#source('property/test_properties.dart');

void runDartlibTests() {
  group('dartlib', (){
    TestEnumerable.run();
    TestNumberEnumerable.run();
    TestListBase.run();
    TestCollectionUtil.run();
    TestArray2d.run();

    TestCoordinate.run();
    TestRect.run();
    TestVector.run();
    TestAffineTransform.run();

    TestUtil.run();
    TestCloneable.run();
    TestEvents.run();

    TestTarjanCycleDetect.run();

    TestRgbColor.run();
    TestHslColor.run();

    test('Tuple', (){
      var t1 = new Tuple<int, int>(5, 4);
      expect(t1, equals(t1));
      expect(t1.Item1, equals(5));
      expect(t1.Item2, equals(4));

      var t2 = new Tuple<int, int>(5, 4);
      expect(t2, equals(t1));
      t2 = new Tuple<int, int>(6,4);
      expect(t2, isNot(equals(t1)));
    });

    group('property', (){
      TestProperties.run();
      TestPropertyEventIntegration.run();
    });
});
}