{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
module NLP.Probability.ConditionalDistribution where 
import qualified Data.Map as M
import Data.Maybe (fromJust)
import Data.Monoid
import NLP.Probability.Trie
import NLP.Probability.Distribution
import NLP.Probability.Observation

type CondObserved event context = 
    Trie (Sub context) (Observed event)

singletonObservation :: (Context context, Ord event) => event -> context -> CondObserved event context
singletonObservation event context = 
    addColumn decomp observed mempty 
        where observed = singleton event 
              decomp = decompose context 

type DistributionTree events context = 
    Trie (Sub context) (Distribution events)

class (Ord (Sub a)) => Context a where 
    type Sub a 
    decompose ::  a -> [Sub a]
    compose :: [Sub a] -> a 

newtype SimpleContext = SimpleContext (Int, Int) 

instance Context SimpleContext where 
    type Sub SimpleContext = Int
    decompose (SimpleContext (a,b)) = [a,b]
    compose [a,b] = SimpleContext (a,b)

toCondDistribution :: (Context c) => 
                      DistributionTree events c -> 
                      CondDistribution events c
toCondDistribution tree = 
    CondDistribution $ \context -> fromJust $ find (decompose context) tree    

estimateConditional n est obs =
    CondDistribution $ \context -> M.findWithDefault (uniform n) condMap context 
    where 
     condMap = M.fromList $ 
               map (\(letters, holder) -> (compose letters, est holder)) $ 
               expand_ obs 
     
data CondDistribution event context = CondDistribution {
       cond :: context -> Distribution event
}

data Trigram = Trigram String String
instance Context Trigram where 
    type Sub Trigram = String
    decompose (Trigram w1 w2) = [w2, w1] 
    compose [w2, w1] = Trigram w1 w2 
    
