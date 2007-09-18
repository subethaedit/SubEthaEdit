import java.util.*;

public class ParseTree {
	private NuanceTerm rootTerm;
	
	/**
	 * @param args
	 */
	public ParseTree(NuanceTerm root)
	{
		this.rootTerm = root;
		linkParentsHelper(rootTerm);
	}
	
	public Vector<NuanceTerminal> getSentence()
	{
		return this.getSentenceHelper(this.rootTerm) ;
	}
	
	private Vector<NuanceTerminal> getSentenceHelper(NuanceTerm nt)
	{		
		if(nt.getClass().equals(NuanceNonTerminal.class))
		{
			NuanceNonTerminal nonTerminal = (NuanceNonTerminal)nt;			
			return getSentenceHelper(nonTerminal.linkedTerm);
		}
		else if(nt.getClass().equals(NuanceTerminal.class))
		{
			NuanceTerminal terminal = (NuanceTerminal)nt;
			Vector<NuanceTerminal> termlist = new Vector<NuanceTerminal>();
			termlist.add(terminal);
			return termlist;
		}
		if(nt.getClass().equals(NuanceConcatenationTermList.class))
		{
			NuanceConcatenationTermList concatenationList = (NuanceConcatenationTermList)nt;
			Vector<NuanceTerminal> termlist = new Vector<NuanceTerminal>();
			for (int i = 0; i< concatenationList.size(); i++)
			{				
				termlist.addAll(getSentenceHelper(concatenationList.get(i)));
			}
			return termlist;
		}
		if(nt.getClass().equals(NuanceAlternativeTermList.class))
		{
			NuanceAlternativeTermList alternativeList = (NuanceAlternativeTermList)nt;
			if (alternativeList.size() != 1)
			{
				System.out.println("Error: alternative list != one child!");
			}
			return getSentenceHelper(alternativeList.get(0));
		}
		if(nt.getClass().equals(NuanceOptionalOperator.class))
		{
			NuanceOptionalOperator optionalOperator = (NuanceOptionalOperator)nt;
			if (optionalOperator.getChild() == null)
			{
				return new Vector<NuanceTerminal>();
			}
			else
			{
				return getSentenceHelper(optionalOperator.getChild());  	
			}
		}		
		return null;
	}
	
	private void linkParentsHelper(NuanceTerm nt)
	{
		if(nt.getClass().equals(NuanceNonTerminal.class))
		{
			NuanceNonTerminal nonTerminal = (NuanceNonTerminal)nt;
			nonTerminal.linkedTerm.parent = nonTerminal.parent;
			linkParentsHelper(nonTerminal.linkedTerm);
		}
		else if(nt.getClass().equals(NuanceTerminal.class))
		{					
		}
		if(nt.getClass().equals(NuanceConcatenationTermList.class))
		{
			NuanceConcatenationTermList concatenationList = (NuanceConcatenationTermList)nt;			
			for (int i = 0; i< concatenationList.size(); i++)
			{				
				concatenationList.get(i).parent = concatenationList;
				linkParentsHelper(concatenationList.get(i));
			}
		}
		if(nt.getClass().equals(NuanceAlternativeTermList.class))
		{
			NuanceAlternativeTermList alternativeList = (NuanceAlternativeTermList)nt;
			if (alternativeList.size() != 1)
			{
				System.out.println("Error: alternative list != one child!");
			}
			alternativeList.get(0).parent = alternativeList;
			linkParentsHelper(alternativeList.get(0));
		}
		if(nt.getClass().equals(NuanceOptionalOperator.class))
		{
			NuanceOptionalOperator optionalOperator = (NuanceOptionalOperator)nt;
			if (optionalOperator.getChild() == null)
			{
				new Vector<NuanceTerminal>();
			}
			else
			{
				optionalOperator.getChild().parent =  optionalOperator;
				linkParentsHelper(optionalOperator.getChild());  	
			}
		}					
	}
	
	private static Vector<NuanceTerm> mirrorVector(Vector<NuanceTerm> vec)
	{
		Vector<NuanceTerm> newVec = new Vector<NuanceTerm>();
		for (int i=vec.size()-1; i >= 0; i--)
		{
			newVec.add(vec.get(i));
		}
		return newVec;
	}
	
	public String toString()
	{
		return rootTerm.toString();
	}
	
	/**
	 *also man legt als erstes die zielposition fest
	 » zielposition ist ein blatt und es wird versucht immer direkt rechts davon ainzufügen
	 » sobald man das zielblatt festgelegt hat, werden alle alle kinderlisten auf dem weg zur wurzel teilweise oder ganz gesperrt
	 » und zwar auf jeden fall die elemente, die den direkten weg bilden aber implizit auch alle elemente in den listen 
	 die weiter links als das entsprechende element auf der jeweiligen ebene liegen
	 » d.h. nach der aktion ist im prinzip der baum in zwei teile geteilt: einer hälfte die nicht eingerührt wird und eine anderen, 
	 die verändert werden darf
	 jetzt geht man von der wurzel wieder nach unten
	 » und rotiert von oben nach unten
	 » sobald man einen gesperrten eintrag verschieben müsste schlägt das verfahren fehl
	 » die vom zielblatt zur wurzel
	 ich lasse es nicht zu dass bei den rotationsoperationen das zielblatt verschoben wird
	 damit sich die linke seite des satzes nicht mehr ändern kann
	 und dann versuche ich das zu verschiebende blatt im prinzip an die linkest mögliche position zu bekommen
	 */	
	
	/**
	 * Move a terminal to a new position while preserving any parent-child relationships.
	 * @param terminalToMove The terminal which sould be moved.
	 * @param targetTerminal The target terminal. The terminalToMove will be moved right of targetTerminal if possible.
	 * @return true if the terminal could be moved successfully
	 */
	
	public boolean moveTerminal(NuanceTerminal terminalToMove,
			NuanceTerminal targetTerminal) throws
			RuntimeException
			{
		//get the terminal list (the leaf list basically)
		Vector<NuanceTerminal> terminals = getSentence();
		
		//do some checks first
		if (!terminals.contains(terminalToMove))
			throw new RuntimeException(
			"Terminal to move is not part of the parse tree.");
		
		if (targetTerminal!=null)
			if (!terminals.contains(targetTerminal))
				throw new RuntimeException(
				"Target terminal is not part of the parse tree.");
		
		//get the node list from the target to the root
		//this will be the "locked-node" list.
		//all nodes in this list and all siblings left of these nodes will not be moved.
		NuanceTerm node;
		Vector<NuanceTerm> targetToRootPath = new
		Vector<NuanceTerm>();
		if (targetTerminal!=null)
		{
			node = targetTerminal;
			while (node != null) {
				targetToRootPath.add(node);
				node = node.parent;
			}
			targetToRootPath =
				mirrorVector(targetToRootPath);
		}
		
		//get the node list from the "node to move" to the root
		Vector<NuanceTerm> sourceToRootPath = new
		Vector<NuanceTerm>();
		node = terminalToMove;
		while (node != null) {
			sourceToRootPath.add(node);
			node = node.parent;
		}
		sourceToRootPath = mirrorVector(sourceToRootPath);
		
		//check if we can move the source node right to the target node at all
		//(walk down to the target)
		for (int i = 0; i < targetToRootPath.size() - 1; i++)
		{
			node = targetToRootPath.get(i);
			// check if the source and target path have a common node
			boolean isCommonNode = i <
			sourceToRootPath.size() ?
					node == sourceToRootPath.get(i)
					: false;
					//we only can rotate if the have a concatenation list	
			if (node.getClass().equals(NuanceConcatenationTermList.class))
			{
				NuanceConcatenationTermList concList =
					(NuanceConcatenationTermList) node;
				if (isCommonNode)
				{
					int sourceNodeIndex =
						concList.indexOf(sourceToRootPath.get(i + 1));
					int targetNodeIndex =
						concList.indexOf(targetToRootPath.get(i + 1));
					
					//we cannot move the source node to the left of the target node
					if (sourceNodeIndex <
							targetNodeIndex)
						return false;
					
				}
				else
				{
					int targetNodeIndex =
						concList.indexOf(targetToRootPath.get(i + 1));
					
					//the target isnt the rightmost 
					if (targetNodeIndex <
							concList.size()-1)
						return false;
					
				}
			}
		}
		
		// now rotate beginning from the root node
		//(walk down to the source)
		for (int i=0; i < sourceToRootPath.size()-1; i++)
		{
			node = sourceToRootPath.get(i);
			//check if the source and target path have a common node
			boolean isCommonNode = i <
			targetToRootPath.size() ?
					node==targetToRootPath.get(i):
						false;
			//we only can rotate if the have a concatenation list	
			if
			(node.getClass().equals(NuanceConcatenationTermList.class))
			{
				NuanceConcatenationTermList concList =
					(NuanceConcatenationTermList)node;
				if (isCommonNode)
				{
					//we have a common node --> we need to check whether our rotation operation is possible
					int sourceNodeIndex =
						concList.indexOf(sourceToRootPath.get(i+1));
					int targetNodeIndex =
						concList.indexOf(targetToRootPath.get(i+1));
					
					//we cannot move the source node to the left of the target node
					if (sourceNodeIndex <
							targetNodeIndex)
						return false;
					
					//we can move this one furtherto the left
					if (sourceNodeIndex >
					targetNodeIndex + 1)
					{
						
						concList.moveChild(sourceNodeIndex, targetNodeIndex+1);
					}
				}
				else
				{
					//no common node --> we can do whatever we want
					int sourceNodeIndex =
						concList.indexOf(sourceToRootPath.get(i+1));
					
					//we can move this one to the leftmost position in the concat list
					if (sourceNodeIndex > 0)
					{
						
						concList.moveChild(sourceNodeIndex, 0);
					}	
				}
			}
		}
		return true;
	}
	
	
	public void deleteSingles(Alignment a)
	{
		Vector<String> targetWords = a.getTargetWords();
		Vector<String> sourceWords = a.getSourceWords();
		Integer[] sourceAlignmentPartners = new Integer[sourceWords.size()];
//		Vector<Integer> targetAlignmentPartners = new Vector<Integer>();
		Vector<AlignmentItem> alignmentItems = a.getAlignmentItems();
		
		for (int j = 0; j < alignmentItems.size(); j++)
		{//loop over alignment items and set sourceAlignmentPartners
			sourceAlignmentPartners[alignmentItems.get(j).getIndexSource()] = alignmentItems.get(j).getIndexTarget();	
		}
		// delete words in source parse tree that have no alignment partner
		for (int k = 0; k < sourceWords.size(); k++)
		{
			if (sourceAlignmentPartners[k] == null) 
			{
				System.out.println("word to kill: " + a.getSourceWordAt(k));
				System.out.println("terminal to kill: " + getTerminalByName(a.getSourceWordAt(k)));
				deleteTerminal(getTerminalByName(a.getSourceWordAt(k)));
			}				
		}
		
		for (int i = 0; i < sourceAlignmentPartners.length; i++)
		{
			System.out.println("sourceAlignmentPartners[i]:= "+ sourceAlignmentPartners[i]);	
		}
	}
	
	public ParseTree reorderTree(Alignment a) throws RuntimeException
	{
		Vector<String> targetWords = a.getTargetWords();
		Vector<String> sourceWords = a.getSourceWords();
		Vector<AlignmentItem> alignmentItems = a.getAlignmentItems();
		Vector<String> insertionWords = new Vector<String>();		
		
		for (int i = 0; i < targetWords.size(); i++)
		{
			//check if all targetwords are present in the terminal list; if not, insert missing words into vector insertionWords
			if (!getSentence().contains(a.getTargetWordAt(i)))
			{
				insertionWords.add(a.getTargetWordAt(i));
//				throw new RuntimeException("Terminal "+a.getTargetWordAt(i)+" is missing in terminal list.");
			}
		}
		
		for (int i=0; i<insertionWords.size(); i++)
		{		//the words in the alignment target that have to be inserted into the parsetree later
//			targetWords.remove(insertionWords.get(i));
		}
		
		if (getSentence().size() != targetWords.size())
		{
			//throw new RuntimeException("ParseTree has " + pt.getSentence().size() + " words; Alignment has "+ targetWords.size() +"!" );
		}
		//now both sentences should have the same amount of words. 
		//insert sort parse tree after alignment order!
		//i and j are indices on the targetword order, the parse tree order will be adapted
		// moveTerminal for all terminals

		NuanceTerminal targetTerminal = null;
		for (int i = 0; i < targetWords.size(); i++)
		{								
			NuanceTerminal terminalToMove = getTerminalByName(targetWords.get(i));
			
	//		System.out.println("targetWords.get(" + i + "): " + targetWords.get(i));
		//	System.out.println("terminalToMove: " + terminalToMove);
			
	//		targetTerminal = getSentence().get(i);
			
			//System.out.println("targetTerminal: " + targetTerminal);
			
			moveTerminal(terminalToMove, targetTerminal);	
						
			System.out.println("moved "+ terminalToMove+ " behind " + targetTerminal+ ": "+ moveTerminal(terminalToMove, targetTerminal));
			//System.out.println(getSentence());
			targetTerminal = terminalToMove;
		}
		//TODO check if sentences match!!
		return this;			
	}
	
	
	
	public NuanceTerminal getTerminalByName(String name)
	//returns a NuanceTerminal if it exists in the Vector, else returns null
	//TODO what about duplicates?
	{
		Vector<NuanceTerminal> list = getSentence();
		for (int i = 0; i< list.size(); i++)
		{
			if (list.get(i).getTermId().equals(name)) return list.get(i);
		}
		return null;	
	}
	
	public boolean substituteTerminals(Alignment a) 
	//insertion sort style
	//returns true if it substituted the terminals in the source language with target language symbols
	//else false
	{
		Vector<NuanceTerminal> terminals = getSentence();
		Vector<String> targetWords = a.getTargetWords();
		Vector<AlignmentItem> alignmentItems = a.getAlignmentItems();
		String substituteWord;
		NuanceTerminal substTerminal;
		NuanceTermList termList;
		NuanceConcatenationTermList catList;  
		int currentSourceIndex =0;
		int currentTargetIndex =0;
		//a vector of integer-vectors
		Vector<Vector<Integer>> countTargets = new Vector<Vector<Integer>>();
		Vector<Vector<Integer>> countSources = new Vector<Vector<Integer>>();
		
		//have to check if an alignment item is one to one, if yes replace
		//else if one to many, replace by concatenationList of many 
		//else if many to many or one to many, replace (with cat) and delete obsolete parents 
		//if (terminals.size() < alignmentItems.size()) System.out.println("more alignments than terminals.");
		//else if (terminals.size() > alignmentItems.size()) System.out.println("more terminals than alignments.");
		
//		fill the countTargetsVector
		for (int i = 0; i< terminals.size(); i++)
		{
//			iVector contains all target indices that i is aligned with
			Vector<Integer> iVector = new Vector<Integer>();
			for (int j = 0; j< alignmentItems.size(); j++)
			{
				currentSourceIndex = alignmentItems.get(j).getIndexSource();
				currentTargetIndex = alignmentItems.get(j).getIndexTarget();
				
				if (i==currentSourceIndex)
				{
					iVector.add(currentTargetIndex);
				}	
			}
			countTargets.add(iVector);	
//			System.out.println("iVector.toString() Targets = " + iVector.toString());
		}
//		System.out.println("countTargets.toString()= " + countTargets.toString());
		
		
//		fill the countSources Vector
		for (int i = 0; i< targetWords.size(); i++)
		{
//			jVector contains all source indices that j is aligned with
			Vector<Integer> jVector = new Vector<Integer>();
			for (int j = 0; j< alignmentItems.size(); j++)
			{
				currentSourceIndex = alignmentItems.get(j).getIndexSource();
				currentTargetIndex = alignmentItems.get(j).getIndexTarget();
				
				if (i==currentTargetIndex)
				{
					jVector.add(currentSourceIndex);
				}	
			}
			countSources.add(jVector);	
			//System.out.println("iVector.toString() Sources= " + jVector.toString());
		}
		
		//now replace terminals using the count vectors to check the case (one/many-to-one/many)
		Vector<Vector<Integer>> block = new Vector<Vector<Integer>>();
		//call findBlocks for all terminal symbols
		for (int i = 0; i< terminals.size(); i++)
		{
			Vector<Vector<Integer>> foundLists = new Vector<Vector<Integer>>();
			Vector<Integer> source = new Vector<Integer>();
			Vector<Integer> target = new Vector<Integer>();
			foundLists.add(source);
			foundLists.add(target);
			block = findBlocks(i, true, foundLists, countTargets, countSources);
			
//			System.out.println("foundLists = " + foundLists.toString());
			
			//now substitute blockwise: first string target words together
			substituteWord = targetWords.get(block.get(1).get(0));
			if (block.get(1).size() > 1) //one to many substitution, have to insert concat list
			{
				termList = new NuanceTermList();
				for (int k = 0; k< block.get(1).size(); k++ )
				{
					substituteWord = targetWords.get(block.get(1).get(k));
					substTerminal = new NuanceTerminal(substituteWord);
					termList.addTerm(substTerminal);
					//substTerminal.setParent(termList);
				}
				catList = new NuanceConcatenationTermList(termList);
				
				replaceByMany(terminals.get(block.get(0).get(0)), catList);
//				System.out.println("new terminals are: "+ terminals);
			}
			else if (block.get(1).size() == 1) //one to one substitution, just change terminal name
			{				
				terminals.get(block.get(0).get(0)).setName(substituteWord);
			}
			
			//substitute leftmost terminal with substitute string
			//delete siblings of leftmost terminal
			for (int k = 1; k< block.get(0).size(); k++)
			{
			//	deleteTerminal(terminals.get(k));
			}
//			System.out.println("substitute sourceWords(" + currentSourceIndex + ")=" + word + " with targetwords("+currentTargetIndex +")=" + substitute);
		}
		return true;
	}
	
	public Vector<Vector<Integer>> findBlocks(int index, boolean belongsToSource, Vector<Vector<Integer>> foundLists, 
			Vector<Vector<Integer>> countTargets,  Vector<Vector<Integer>> countSources)
	{
		//int belongsTo ist 0 for sourcelist, 1 for targetlist!	
		
		//termination criterion:		
		if (((belongsToSource) && foundLists.get(0).contains(index)) || ((!belongsToSource) && foundLists.get(1).contains(index)))
		{
			return foundLists;
		}			
		//wort index einfügen in die liste wos reingehört
		//im vector nach links suchen und bei gefundenen worten rekursiver aufruf mit !belongsToSource
		if (belongsToSource)
		{
			foundLists.get(0).add(index);
			for (int i=0; i< countTargets.get(index).size(); i++ )
			{
				foundLists = findBlocks(countTargets.get(index).get(i), !belongsToSource, foundLists, countTargets, countSources);
			}
		}
		else 
		{
			foundLists.get(1).add(index);
			for (int i=0; i< countSources.get(index).size(); i++ )
			{
				
				foundLists = findBlocks(countSources.get(index).get(i), !belongsToSource, foundLists, countTargets, countSources);
			}
		}			
		return foundLists;
	}
	
	public void deleteTerminal(NuanceTerminal terminalToDelete) throws RuntimeException
	{
		NuanceTerm parent;
		NuanceTerm termToDelete = (NuanceTerm)terminalToDelete;
		
		if (terminalToDelete!=null)
		{
			parent = terminalToDelete.getParent();
			while (parent != null){
				if (parent.getClass().equals(NuanceConcatenationTermList.class))
				{
					NuanceConcatenationTermList parentList = (NuanceConcatenationTermList)parent;
					if (parentList.size() > 1)
					{
						parentList.removeTerm(termToDelete);		
						break;
					}
				}
				else if (parent.getClass().equals(NuanceAlternativeTermList.class))
				{
					termToDelete = (NuanceAlternativeTermList)parent;
				}
				else if (parent.getClass().equals(NuanceOptionalOperator.class))
				{
					termToDelete = (NuanceOptionalOperator)parent;
				}
				parent = parent.getParent();
			}
		}
	}
	
	public void replaceByMany(NuanceTerminal terminalToReplace, NuanceConcatenationTermList catList)
	{
	//replaces a terminal by a concatenation list of many terminals to handle one-to-many alignments
		NuanceTerm parent;
		catList.setParent(terminalToReplace.getParent());
		if (terminalToReplace!=null)
		{
			parent = terminalToReplace.getParent();
			if (parent.getClass().equals(NuanceConcatenationTermList.class))
			{
				NuanceConcatenationTermList list = (NuanceConcatenationTermList)parent;
				list.replaceChild(terminalToReplace, catList);
				
			}
			else if (parent.getClass().equals(NuanceAlternativeTermList.class))
			{
				NuanceAlternativeTermList list = (NuanceAlternativeTermList)parent;				
				list.replaceTerm(terminalToReplace, catList);
				
			}
			else if (parent.getClass().equals(NuanceOptionalOperator.class))
			{
				NuanceOptionalOperator opt = (NuanceOptionalOperator)parent;				
				opt.setChild(catList);				
			}			
		}
	}

	
	public Vector<NuanceProduction> splitTreeHelper(NuanceTerm startTerm)
	{
		Vector<NuanceProduction> productions = new Vector<NuanceProduction>();
		if (startTerm.isTopLevel())
		{
						
			//and attach a new NuanceNonTerminal node as leaf using the start terminal's id
			if (startTerm.getParent()!=null)
			{
				NuanceNonTerminal leaf = new NuanceNonTerminal(startTerm.getTermId());
				startTerm.getParent().replaceChild(startTerm, leaf);
				
			}
			
			//we need to unlink this node from its parent
			startTerm.setParent(null);
			
			//found new production root
			productions.add(new NuanceProduction(new NuanceNonTerminal(startTerm.getTermId()), startTerm));
		}
		
		//call the overloaded method to get the children of the term
		Vector<NuanceTerm> children = startTerm.getChildren();
			
		for (int i = 0; i < children.size(); i++)
		{
			//call recursively
			productions.addAll(splitTreeHelper(children.get(i)));
		}
				
		return productions;
	}
	
	//baum durchlaufen bis istoplevel oder blatt gefunden, rechte seite abtrennen, platzhalter einfügen, 
	//recursiv aufrufen mit toplevel, gibt vector von nuanceterm zurück.  
	public Vector<NuanceProduction> splitTree()
	{
		return splitTreeHelper(rootTerm);
		
	}

} 


